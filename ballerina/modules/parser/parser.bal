// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import yaml.lexer;
import yaml.common;

public enum ParserOption {
    DEFAULT,
    EXPECT_MAP_KEY,
    EXPECT_MAP_VALUE,
    EXPECT_SEQUENCE_ENTRY,
    EXPECT_SEQUENCE_VALUE
}

public enum DocumentType {
    ANY_DOCUMENT,
    BARE_DOCUMENT,
    DIRECTIVE_DOCUMENT
}

# Obtain an event for the for a set of tokens.
#
# + state - Current parser state  
# + option - Expected values inside a mapping collection  
# + docType - Document type to be parsed
# + return - Parsed event on success. Else, a lexical or a parsing error on failure.
public isolated function parse(ParserState state, ParserOption option = DEFAULT, DocumentType docType = BARE_DOCUMENT) returns common:Event|ParsingError {
    // Empty the event buffer before getting new tokens
    if state.eventBuffer.length() > 0 {
        return state.eventBuffer.shift();
    }
    state.updateLexerContext(lexer:LEXER_START);
    check checkToken(state);

    // Ignore the whitespace at the head
    if state.currentToken.token == lexer:SEPARATION_IN_LINE {
        check checkToken(state);
    }

    // Set the next line if the end of line is detected
    if state.currentToken.token == lexer:EOL || state.currentToken.token == lexer:EMPTY_LINE
        || state.currentToken.token == lexer:COMMENT {

        if state.isEndOfFile() {
            if docType == DIRECTIVE_DOCUMENT {
                return generateExpectError(state, lexer:DIRECTIVE_MARKER, lexer:DIRECTIVE);
            }
            return {
                endType: common:STREAM
            };
        }
        check state.initLexer();
        return parse(state, option, docType);
    }

    // Only directive tokens are allowed in directive document
    if state.currentToken.token != lexer:DIRECTIVE && state.currentToken.token != lexer:DIRECTIVE_MARKER {
        if docType == DIRECTIVE_DOCUMENT {
            return generateGrammarError(state, string `'${state.currentToken.token}' is not allowed in a directive document`);
        }
        state.directiveDocument = false;
    }

    match state.currentToken.token {
        lexer:DIRECTIVE => {
            // Directives are not allowed in bare documents
            if docType == BARE_DOCUMENT {
                return generateGrammarError(state, "Directives are not allowed in a bare document");
            }

            match state.currentToken.value {
                "YAML" => {
                    check yamlDirective(state);
                }
                "TAG" => {
                    check tagDirective(state);
                }
                _ => {
                    check reservedDirective(state);
                }
            }
            check checkToken(state, [lexer:SEPARATION_IN_LINE, lexer:EOL]);

            state.directiveDocument = true;
            return check parse(state, docType = DIRECTIVE_DOCUMENT);
        }
        lexer:DOCUMENT_MARKER|lexer:DIRECTIVE_MARKER => {
            boolean explicit = state.currentToken.token == lexer:DIRECTIVE_MARKER;
            state.explicitDoc = explicit;

            check checkToken(state, [lexer:SEPARATION_IN_LINE, lexer:EOL, lexer:COMMENT]);
            state.lexerState.resetState();

            if !explicit {
                state.yamlVersion = ();
                state.customTagHandles = {};
            }

            if state.currentToken.token == lexer:SEPARATION_IN_LINE {
                check checkToken(state, peek = true);
                // There cannot be nodes next to the document marker.
                if state.tokenBuffer.token != lexer:EOL && state.tokenBuffer.token != lexer:COMMENT && !explicit {
                    return generateGrammarError(state,
                        string `'${state.tokenBuffer.token}' token cannot start in the same line as the document marker`);
                }

                // Block collection nodes cannot be next to the directive marker.
                if explicit && (state.tokenBuffer.token == lexer:PLANAR_CHAR && state.tokenBuffer.indentation != ()
                    || state.tokenBuffer.token == lexer:SEQUENCE_ENTRY) {
                    return generateGrammarError(state,
                            string `'${state.tokenBuffer.token}' token cannot start in the same line as the directive marker`);
                }
            }
            return {
                explicit
            };
        }
        lexer:DOUBLE_QUOTE_DELIMITER|lexer:SINGLE_QUOTE_DELIMITER|lexer:PLANAR_CHAR|lexer:ALIAS => {
            return appendData(state, option, peeked = true);
        }
        lexer:TAG|lexer:TAG_HANDLE|lexer:ANCHOR => {
            return nodeComplete(state, option);
        }
        lexer:MAPPING_VALUE => { // Empty node as the key
            if state.lexerState.isFlowCollection() {
                if option == EXPECT_SEQUENCE_ENTRY || option == EXPECT_SEQUENCE_VALUE {
                    state.eventBuffer.push({value: ()});
                    return {startType: common:MAPPING, implicit: true};
                }
                return {value: ()};
            } else {
                lexer:Indentation indentation = <lexer:Indentation>state.currentToken.indentation;
                check separate(state);
                match indentation.change {
                    1 => { // Increase in indent
                        state.eventBuffer.push({value: ()});
                        return {startType: common:MAPPING};
                    }
                    0 => { // Same indent
                        return {value: ()};
                    }
                    -1 => { // Decrease in indent
                        foreach common:Collection collectionItem in indentation.collection {
                            state.eventBuffer.push({endType: collectionItem});
                        }
                        if option == EXPECT_MAP_VALUE {
                            state.eventBuffer.push({value: ()});
                        }
                        return state.eventBuffer.shift();
                    }
                }
            }
        }
        lexer:SEPARATOR => { // Empty node as the value in flow mappings
            if option == EXPECT_MAP_VALUE { // Check for empty values in flow mappings
                return {value: ()};
            }
        }
        lexer:MAPPING_KEY => { // Explicit key
            state.explicitKey = true;
            state.lastExplicitKeyLine = state.lineIndex;
            return appendData(state, option);
        }
        lexer:SEQUENCE_ENTRY => {
            if state.lexerState.isFlowCollection() {
                return generateGrammarError(state, "Cannot have block sequence under flow collection");
            }
            if state.expectBlockSequenceValue {
                return generateGrammarError(state, "Cannot have nested sequence for a defined value");
            }
            match (<lexer:Indentation>state.currentToken.indentation).change {
                1 => { // Indent increase
                    return {startType: common:SEQUENCE};
                }
                0 => { // Sequence entry
                    common:Event event = check parse(state, EXPECT_SEQUENCE_VALUE, docType);
                    if option == EXPECT_SEQUENCE_VALUE {
                        state.eventBuffer.push(event);
                        return {value: ()};
                    }
                    return event;
                }
                -1 => { //Indent decrease 
                    foreach common:Collection collectionItem in (<lexer:Indentation>state.currentToken.indentation).collection {
                        state.eventBuffer.push({endType: collectionItem});
                    }
                    return state.eventBuffer.shift();
                }
            }
        }
        lexer:MAPPING_START => {
            return {startType: common:MAPPING, flowStyle: true};
        }
        lexer:SEQUENCE_START => {
            return {startType: common:SEQUENCE, flowStyle: true};
        }
        lexer:SEQUENCE_END => {
            if state.lexerState.isFlowCollection() {
                check separate(state);
                if state.tokenBuffer.token == lexer:SEPARATOR {
                    check checkToken(state);
                } else if state.tokenBuffer.token != lexer:MAPPING_END
                    && state.tokenBuffer.token != lexer:SEQUENCE_END {
                    return generateExpectError(state,
                        [lexer:SEPARATOR, lexer:MAPPING_END, lexer:SEQUENCE_END], lexer:MAPPING_END);
                }
            }
            return {endType: common:SEQUENCE};
        }
        lexer:MAPPING_END => {
            if option == EXPECT_MAP_VALUE {
                state.eventBuffer.push({endType: common:MAPPING});
                return {value: ()};
            }
            if state.lexerState.isFlowCollection() {
                check separate(state);
                if state.tokenBuffer.token == lexer:SEPARATOR {
                    check checkToken(state);
                } else if state.tokenBuffer.token != lexer:MAPPING_END
                    && state.tokenBuffer.token != lexer:SEQUENCE_END {
                    return generateExpectError(state,
                        [lexer:SEPARATOR, lexer:MAPPING_END, lexer:SEQUENCE_END], lexer:MAPPING_END);
                }
            }
            return {endType: common:MAPPING};
        }
        lexer:LITERAL|lexer:FOLDED => {
            state.updateLexerContext(lexer:LEXER_LITERAL);
            return appendData(state, option, peeked = true);
        }
    }

    return generateGrammarError(state, string `Invalid token '${state.currentToken.token}' as the first for generating an event`);
}

# Check if the given string is a valid planar scalar.
#
# + value - The string to be checked
# + return - True if the string is a valid planar scalar. Else, false.
public isolated function isValidPlanarScalar(string value) returns boolean {
    string? planarScalarResult = ();
    do {
        ParserState parserState = check new ([value]);
        planarScalarResult = check planarScalar(parserState, false);
    } on fail {
        return false;
    }
    return planarScalarResult is string && planarScalarResult.trim() == value.trim();
}

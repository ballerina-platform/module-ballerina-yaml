import yaml.lexer;
import yaml.event;

public enum ParserOption {
    DEFAULT,
    EXPECT_KEY,
    EXPECT_VALUE
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
public function parse(ParserState state, ParserOption option = DEFAULT, DocumentType docType = BARE_DOCUMENT) returns event:Event|lexer:LexicalError|ParsingError {
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
    if state.currentToken.token == lexer:EOL || state.currentToken.token == lexer:EMPTY_LINE {
        if state.lineIndex >= state.numLines - 1 {
            return {
                endType: event:STREAM
            };
        }
        check state.initLexer();
        return parse(state, docType = docType);
    }

    // Only directive tokens are allowed in directive document
    if docType == DIRECTIVE_DOCUMENT
        && !(state.currentToken.token == lexer:DIRECTIVE || state.currentToken.token == lexer:DIRECTIVE_MARKER) {
        return generateError(state, string `'${state.currentToken.token}' is not allowed in a directive document`);
    }

    match state.currentToken.token {
        lexer:DIRECTIVE => {
            // Directives are not allowed in bare documents
            if docType == BARE_DOCUMENT {
                return generateError(state, "Directives are not allowed in a bare document");
            }

            if (state.currentToken.value == "YAML") { // YAML directive
                check yamlDirective(state);
                check checkToken(state, [lexer:SEPARATION_IN_LINE, lexer:EOL]);
            } else { // TAG directive
                check tagDirective(state);
                check checkToken(state, [lexer:SEPARATION_IN_LINE, lexer:EOL]);
            }
            return check parse(state, docType = DIRECTIVE_DOCUMENT);
        }
        lexer:DIRECTIVE_MARKER => {
            return {
                startType: event:DOCUMENT
            };
        }
        lexer:DOUBLE_QUOTE_DELIMITER|lexer:SINGLE_QUOTE_DELIMITER|lexer:PLANAR_CHAR => {
            return appendData(state, option, peeked = true);
        }
        lexer:ALIAS => {
            string alias = state.currentToken.value;
            return {
                    alias
                };
        }
        lexer:TAG_HANDLE => {
            string tagHandle = state.currentToken.value;

            // Obtain the tagPrefix associated with the tag handle
            state.updateLexerContext(lexer:LEXER_TAG_NODE);
            check checkToken(state, lexer:TAG);
            string tagPrefix = state.currentToken.value;

            // Check if there is a separate 
            check separate(state);

            // Obtain the anchor if there exists
            string? anchor = check nodeAnchor(state);

            return appendData(state, option,
                {tag: check generateCompleteTagName(state, tagHandle, tagPrefix), anchor});
        }
        lexer:TAG => {
            // Obtain the tagPrefix name
            string tagPrefix = state.currentToken.value;

            // There must be a separate after the tagPrefix
            check separate(state);

            // Obtain the anchor if there exists
            string? anchor = check nodeAnchor(state);

            return appendData(state, option, {tag: tagPrefix, anchor});
        }
        lexer:ANCHOR => {
            // Obtain the anchor name
            string anchor = state.currentToken.value;

            // Check if there is a separate
            check separate(state);

            // Obtain the tag if there exists
            string? tagHandle;
            string? tagPrefix;
            [tagHandle, tagPrefix] = check nodeTag(state);

            // Construct the complete tag
            string? tag;
            if tagPrefix == () {
                tag = ();
            } else {
                if tagHandle == () {
                    tag = tagPrefix;
                } else {
                    tag = check generateCompleteTagName(state, tagHandle, tagPrefix);
                }
            }

            return appendData(state, option, {tag, anchor});
        }
        lexer:MAPPING_VALUE => { // Empty node as the key
            lexer:Indentation? indentation = state.currentToken.indentation;
            if indentation == () {
                return generateError(state, "Empty key requires an indentation");
            }
            check separate(state);
            match indentation.change {
                1 => { // Increase in indent
                    state.eventBuffer.push({value: ()});
                    return {startType: event:MAPPING};
                }
                0 => { // Same indent
                    return {value: ()};
                }
                -1 => { // Decrease in indent
                    foreach event:Collection collectionItem in indentation.collection {
                        state.eventBuffer.push({endType: collectionItem});
                    }
                    return state.eventBuffer.shift();
                }
            }
        }
        lexer:SEPARATOR => { // Empty node as the value in flow mappings
            return {value: ()};
        }
        lexer:MAPPING_KEY => { // Explicit key
            state.explicitKey = true;
            return appendData(state, option);
        }
        lexer:SEQUENCE_ENTRY => {
            if state.currentToken.indentation == () {
                return generateError(state, "Block sequence must have an indentation");
            }
            match (<lexer:Indentation>state.currentToken.indentation).change {
                1 => { // Indent increase
                    return {startType: event:SEQUENCE};
                }
                0 => { // Sequence entry
                    return parse(state);
                }
                -1 => { //Indent decrease 
                    foreach event:Collection collectionItem in (<lexer:Indentation>state.currentToken.indentation).collection {
                        state.eventBuffer.push({endType: collectionItem});
                    }
                    return state.eventBuffer.shift();
                }
            }
        }
        lexer:MAPPING_START => {
            return {startType: event:MAPPING, flowStyle: true};
        }
        lexer:SEQUENCE_START => {
            return {startType: event:SEQUENCE, flowStyle: true};
        }
        lexer:DOCUMENT_MARKER => {
            state.lexerState.resetState();
            state.yamlVersion = ();
            return {endType: event:DOCUMENT};
        }
        lexer:SEQUENCE_END => {
            return {endType: event:SEQUENCE};
        }
        lexer:MAPPING_END => {
            return {endType: event:MAPPING};
        }
        lexer:LITERAL|lexer:FOLDED => {
            state.updateLexerContext(lexer:LEXER_LITERAL);
            string value = check blockScalar(state, state.currentToken.token == lexer:FOLDED);
            return {value};
        }
    }
    return generateError(state, string `Invalid token '${state.currentToken.token}' as the first for generating an event`);
}

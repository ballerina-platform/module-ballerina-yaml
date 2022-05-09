import yaml.lexer;
import yaml.common;

# Merge tag structure with the respective data.
#
# + state - Current parser state  
# + option - Selected parser option  
# + tagStructure - Constructed tag structure if exists  
# + peeked - If the expected token is already in the state
# + return - The constructed scalar or start event on success.
function appendData(ParserState state, ParserOption option, map<json> tagStructure = {}, boolean peeked = false) returns common:Event|lexer:LexicalError|ParsingError {
    lexer:Indentation? indentation = ();
    if state.explicitKey {
        indentation = state.currentToken.indentation;
        check separate(state, true);
    }

    string|common:Collection? value = check content(state, peeked);
    common:Event? buffer = ();

    if !state.explicitKey {
        indentation = state.currentToken.indentation;
    }

    state.explicitKey = false;

    // Check if the current node is a key
    boolean isJsonKey = state.lexerState.isJsonKey;

    // Ignore the whitespace and lines if there is any
    check separate(state, true);
    check checkToken(state, peek = true);

    // Check if the next token is a mapping value or    
    if state.tokenBuffer.token == lexer:MAPPING_VALUE || state.tokenBuffer.token == lexer:SEPARATOR {
        check checkToken(state);
    }

    // If there are no whitespace, and the current token is ':'
    if state.currentToken.token == lexer:MAPPING_VALUE {
        state.lexerState.isJsonKey = false;
        check separate(state, isJsonKey, true);
        if option == EXPECT_VALUE {
            buffer = {value: ()};
        }
    }

    // If there ano no whitespace, and the current token is ","
    if state.currentToken.token == lexer:SEPARATOR {
        check separate(state, true);
        if option == EXPECT_KEY {
            state.eventBuffer.push({value: ()});
        }
    }

    if indentation is lexer:Indentation {
        match indentation.change {
            1 => { // Increased
                // Block sequence
                if value is common:SEQUENCE {
                    return constructEvent(state, tagStructure, {startType: indentation.collection.pop()});
                }
                // Block mapping
                state.eventBuffer.push({value});
                return constructEvent(state, tagStructure, {startType: indentation.collection.pop()});
            }
            -1 => { // Decreased 
                buffer = {endType: indentation.collection.shift()};
                foreach common:Collection collectionItem in indentation.collection {
                    state.eventBuffer.push({endType: collectionItem});
                }
            }
        }
    }

    common:Event event = check constructEvent(state, tagStructure, value is common:Collection ? {startType: value} : {value});

    if buffer == () {
        return event;
    }
    state.eventBuffer.push(event);
    return buffer;
}

# Extracts the data for the given node.
#
# + state - Current parser state  
# + peeked - If the expected token is already in the state
# + return - String if a scalar event. The respective collection if a start event. Else, returns an error.
function content(ParserState state, boolean peeked) returns string|common:Collection|lexer:LexicalError|ParsingError|() {
    state.updateLexerContext(state.explicitKey ? lexer:LEXER_EXPLICIT_KEY : lexer:LEXER_START);

    if !peeked {
        check checkToken(state);
    }

    // Check for flow and block nodes
    match state.currentToken.token {
        lexer:SINGLE_QUOTE_DELIMITER => {
            state.lexerState.isJsonKey = true;
            return singleQuoteScalar(state);
        }
        lexer:DOUBLE_QUOTE_DELIMITER => {
            state.lexerState.isJsonKey = true;
            return doubleQuoteScalar(state);
        }
        lexer:PLANAR_CHAR => {
            return planarScalar(state);
        }
        lexer:SEQUENCE_START|lexer:SEQUENCE_ENTRY => {
            return common:SEQUENCE;
        }
        lexer:MAPPING_START => {
            return common:MAPPING;
        }
        lexer:LITERAL|lexer:FOLDED => {
            if state.lexerState.isFlowCollection() {
                return generateGrammarError(state, "Cannot have a block node inside a flow node");
            }
            return blockScalar(state, state.currentToken.token == lexer:FOLDED);
        }
    }

    // Check for empty nodes with explicit keys
    if state.explicitKey {
        match state.currentToken.token {
            lexer:MAPPING_VALUE => {
                return;
            }
            lexer:SEPARATOR => {
                state.eventBuffer.push({value: ()});
                return;
            }
            lexer:MAPPING_END => {
                state.eventBuffer.push({value: ()});
                state.eventBuffer.push({endType: common:MAPPING});
                return;
            }
            lexer:EOL => { // Only the mapping key
                state.eventBuffer.push({value: ()});
                return;
            }
        }
    }

    return generateExpectError(state, "<data-node>", state.prevToken);
}

# Verifies the grammar production for separation between nodes.
#
# + state - Current parser state  
# + optional - If the separation is optional  
# + allowEmptyNode - If it is possible to have an empty node.
# + return - An error on invalid separation.
function separate(ParserState state, boolean optional = false, boolean allowEmptyNode = false) returns ()|lexer:LexicalError|ParsingError {
    state.updateLexerContext(lexer:LEXER_START);
    check checkToken(state, peek = true);

    // If separate is optional, skip the check when either lexer:EOL or separate-in-line is not detected.
    if optional && !(state.tokenBuffer.token == lexer:EOL || state.tokenBuffer.token == lexer:SEPARATION_IN_LINE) {
        return;
    }

    // Consider the separate for the latter contexts
    check checkToken(state);

    if state.currentToken.token == lexer:SEPARATION_IN_LINE {
        // Check for s-b comment
        check checkToken(state, peek = true);
        if state.tokenBuffer.token != lexer:EOL {
            return;
        }
        check checkToken(state);
    }

    // For the rest of the contexts, check either separation in line or comment lines
    while state.currentToken.token == lexer:EOL || state.currentToken.token == lexer:EMPTY_LINE {
        ParsingError? err = state.initLexer();
        if err is ParsingError {
            return optional || allowEmptyNode ? () : err;
        }
        check checkToken(state, peek = true);

        //TODO: account flow-line prefix
        match state.tokenBuffer.token {
            lexer:EOL|lexer:EMPTY_LINE => { // Check for multi-lines
                check checkToken(state);
            }
            lexer:SEPARATION_IN_LINE => { // Check for l-comment
                check checkToken(state);
                check checkToken(state, peek = true);
                if state.tokenBuffer.token != lexer:EOL {
                    return;
                }
                check checkToken(state);
            }
            _ => {
                return;
            }
        }
    }

    return generateExpectError(state, [lexer:EOL, lexer:SEPARATION_IN_LINE], state.currentToken.token);
}

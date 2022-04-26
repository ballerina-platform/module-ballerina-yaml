import yaml.lexer;

function nodeTag(ParserState state) returns [string?, string?]|ParsingError|lexer:LexicalError {
    string? tagPrefix = ();
    string? tagHandle = ();
    match state.tokenBuffer.token {
        lexer:TAG => {
            check checkToken(state);
            tagPrefix = state.currentToken.value;
            check separate(state);
        }
        lexer:TAG_HANDLE => {
            check checkToken(state);
            tagHandle = state.currentToken.value;

            state.updateLexerContext(lexer:LEXER_TAG_NODE);
            check checkToken(state, lexer:TAG);
            tagPrefix = state.currentToken.value;
            check separate(state);
        }
    }

    return [tagHandle, tagPrefix];
}

function nodeAnchor(ParserState state) returns string?|lexer:LexicalError|ParsingError {
    string? anchor = ();
    if state.tokenBuffer.token == lexer:ANCHOR {
        check checkToken(state);
        anchor = state.currentToken.value;
        check separate(state);
    }
    return anchor;
}
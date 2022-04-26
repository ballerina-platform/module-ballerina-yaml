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

function nodeProperties(ParserState state) returns [string?, string?, string?]|lexer:LexicalError|ParsingError {
    string? tagHandle = ();
    string? tagPrefix = ();
    string? anchor = ();

    match state.tokenBuffer.token {
        lexer:TAG|lexer:TAG_HANDLE => {
            [tagPrefix, tagHandle] = check nodeTag(state);
            anchor = check nodeAnchor(state);
        }
        lexer:ANCHOR => {
            anchor = check nodeAnchor(state);
            [tagPrefix, tagHandle] = check nodeTag(state);
        }
    }

    return [tagHandle, tagPrefix, anchor];
}
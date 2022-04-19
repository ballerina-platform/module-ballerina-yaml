import yaml.lexer;

function nodeTagHandle(ParserState state) returns [string?, string?]|ParsingError|lexer:LexicalError {
    string? tag = ();
    string? tagHandle = ();
    match state.tokenBuffer.token {
        lexer:TAG => {
            check checkToken(state);
            tag = state.currentToken.value;
            check separate(state);
        }
        lexer:TAG_HANDLE => {
            check checkToken(state);
            tagHandle = state.currentToken.value;

            state.updateLexerContext(lexer:LEXER_TAG_NODE);
            check checkToken(state, lexer:TAG);
            tag = state.currentToken.value;
            check separate(state);
        }
    }

    return [tagHandle, tag];
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
    string? tag = ();
    string? anchor = ();

    match state.tokenBuffer.token {
        lexer:TAG|lexer:TAG_HANDLE => {
            [tag, tagHandle] = check nodeTagHandle(state);
            anchor = check nodeAnchor(state);
        }
        lexer:ANCHOR => {
            anchor = check nodeAnchor(state);
            [tag, tagHandle] = check nodeTagHandle(state);
        }
    }

    return [tagHandle, tag, anchor];
}
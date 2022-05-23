import yaml.lexer;
import yaml.common;

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

function nodeAnchor(ParserState state) returns string?|ParsingError {
    string? anchor = ();
    if state.tokenBuffer.token == lexer:ANCHOR {
        check checkToken(state);
        anchor = state.currentToken.value;
        check separate(state);
    }
    return anchor;
}

function nodeComplete(ParserState state, ParserOption option) returns common:Event|ParsingError {
    match state.currentToken.token {
        lexer:TAG_HANDLE => {
            string tagHandle = state.currentToken.value;

            // Obtain the tagPrefix associated with the tag handle
            state.updateLexerContext(lexer:LEXER_TAG_NODE);
            check checkToken(state, lexer:TAG);
            string tagPrefix = state.currentToken.value;

            // Check if there is a separate 
            check separate(state, true);

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
                tag = tagHandle == () ? tagPrefix : check generateCompleteTagName(state, tagHandle, tagPrefix);
            }

            return appendData(state, option, {tag, anchor});
        }
    }

    return generateGrammarError(state, "Invalid token to start a node");
}

import yaml.lexer;

# Check the grammar productions for TAG directives.
# Update the tag handles map.
#
# + state - Current parser state
# + return - An error on mismatch.
function tagDirective(ParserState state) returns (lexer:LexicalError|ParsingError)? {
    // Expect a separate in line
    check checkToken(state, lexer:SEPARATION_IN_LINE);

    // Expect a tag handle
    state.updateLexerContext(lexer:LEXER_TAG_HANDLE);
    check checkToken(state, lexer:TAG_HANDLE);
    string tagHandle = state.currentToken.value;
    check checkToken(state, lexer:SEPARATION_IN_LINE);

    // Expect a tag prefix
    state.updateLexerContext(lexer:LEXER_TAG_PREFIX);
    check checkToken(state, lexer:TAG_PREFIX);
    string tagPrefix = state.currentToken.value;

    if (state.tagHandles.hasKey(tagHandle)) {
        return generateError(state, formateDuplicateErrorMessage(tagHandle));
    }
    state.tagHandles[tagHandle] = tagPrefix;
}

# Check the grammar productions for YAML directives.
# Update the yamlVersion of the document.
#
# + state - Current parser state
# + return - An error on mismatch.
function yamlDirective(ParserState state) returns lexer:LexicalError|ParsingError|() {
    // Expect a separate in line.
    check checkToken(state, lexer:SEPARATION_IN_LINE);
    state.updateLexerContext(lexer:LEXER_DIRECTIVE);

    // Expect yaml version
    check checkToken(state, lexer:DECIMAL);
    string lexemeBuffer = state.currentToken.value;
    check checkToken(state, lexer:DOT);
    lexemeBuffer += ".";
    check checkToken(state, lexer:DECIMAL);
    lexemeBuffer += state.currentToken.value;

    // Update the version
    if (state.yamlVersion is null) {
        state.yamlVersion = lexemeBuffer;
        return;
    }

    return generateError(state, formateDuplicateErrorMessage("%YAML"));
}

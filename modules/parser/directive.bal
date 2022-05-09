import ballerina/log;
import yaml.common;
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

    // Tag handles cannot be redefined
    if (state.customTagHandles.hasKey(tagHandle)) {
        return generateDuplicateError(state, tagHandle);
    }

    // Expect a tag prefix
    state.updateLexerContext(lexer:LEXER_TAG_PREFIX);
    check checkToken(state, lexer:TAG_PREFIX);
    string tagPrefix = state.currentToken.value;

    state.customTagHandles[tagHandle] = tagPrefix;
}

# Check the grammar productions for YAML directives.
# Update the yamlVersion of the document.
#
# + state - Current parser state
# + return - An error on mismatch.
function yamlDirective(ParserState state) returns lexer:LexicalError|ParsingError|() {
    // Returns an error if the document version is already defined.
    if state.yamlVersion != () {
        return generateDuplicateError(state, "%YAML");
    }

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

    // The parser only works with versions that is compatible with the major version of the parser.
    float yamlVersion = <float>(check common:processTypeCastingError('float:fromString(lexemeBuffer)));
    if yamlVersion != 1.2 {
        if yamlVersion >= 2.0 || yamlVersion < 1.0 {
            return generateGrammarError(state, string `Incompatible version ${yamlVersion} for the 1.2 parser`);
        }
        log:printWarn(string `The parser is designed for YAML 1.2. Some features may not work with ${yamlVersion}`);
    }
    state.yamlVersion = yamlVersion;
}

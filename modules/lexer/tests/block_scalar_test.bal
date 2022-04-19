import ballerina/test;

@test:Config {
    dataProvider: blockScalarTokenDataGen
}
function testBlockScalarToken(string line, YAMLToken token, string value) returns error? {
    LexerState state = setLexerString(line, LEXER_BLOCK_HEADER);
    check assertToken(state, token, lexeme = value);
}

function blockScalarTokenDataGen() returns map<[string, YAMLToken, string]> {
    return {
        "chomping-indicator strip": ["-", CHOMPING_INDICATOR, "-"],
        "chomping-indicator keep": ["+", CHOMPING_INDICATOR, "+"]
    };
}
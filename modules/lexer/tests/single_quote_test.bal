import ballerina/test;

@test:Config {
    dataProvider: planarDataGen
}
function testPlanarToken(string line, string lexeme) returns error? {
    LexerState state = setLexerString(line);
    check assertToken(state, PLANAR_CHAR, lexeme = lexeme);
}

function planarDataGen() returns map<[string, string]> {
    return {
        "ns-char": ["ns", "ns"],
        ":": ["::0", "::0"],
        "?": ["??", "??"],
        "-": ["--", "--"],
        "ignore-comment": ["plain #comment", "plain"],
        "#": ["plain#comment", "plain#comment"],
        "space": ["plain space", "plain space"],
        "single character": ["a", "a"]
    };
}

@test:Config {}
function testSeparateInLineAfterPlanar() returns error? {
    LexerState state = setLexerString("planar space      ");
    check assertToken(state, PLANAR_CHAR, lexeme = "planar space");
    check assertToken(state, SEPARATION_IN_LINE);
}
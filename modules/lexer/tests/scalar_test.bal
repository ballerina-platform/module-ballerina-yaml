import ballerina/test;

@test:Config {
    dataProvider: escapedCharacterDataGen,
    groups: ["escaped", "lexer"]
}
function testEscapedCharacterToken(string lexeme, string value) returns error? {
    LexerState state = setLexerString("\\" + lexeme, LEXER_DOUBLE_QUOTE);
    check assertToken(state, DOUBLE_QUOTE_CHAR, lexeme = value);
}

function escapedCharacterDataGen() returns map<[string, string]> {
    return {
        "null": ["0", "\u{00}"],
        "bell": ["a", "\u{07}"],
        "backspace": ["b", "\u{08}"],
        "horizontal-tab": ["t", "\t"],
        "line-feed": ["n", "\n"],
        "vertical-tab": ["v", "\u{0b}"],
        "form-feed": ["f", "\u{0c}"],
        "carriage-return": ["r", "\r"],
        "escape": ["e", "\u{1b}"],
        "double-quote": ["\"", "\""],
        "slash": ["/", "/"],
        "backslash": ["\\", "\\"],
        "next-line": ["N", "\u{85}"],
        "non-breaking-space": ["_", "\u{a0}"],
        "line-separator": ["L", "\u{2028}"],
        "paragraph-separator": ["P", "\u{2029}"],
        "space": [" ", " "],
        "x-2": ["x41", "A"],
        "u-4": ["u0041", "A"],
        "U-8": ["U00000041", "A"]
    };
}

@test:Config {
    dataProvider: invalidEscapedCharDataGen,
    groups: ["escaped", "lexer"]
}
function testInvalidEscapedCharacter(string lexeme) {
    assertLexicalError("\\" + lexeme, context = LEXER_DOUBLE_QUOTE);
}

function invalidEscapedCharDataGen() returns map<[string]> {
    return {
        "x-1": ["x1"],
        "u-3": ["u333"],
        "U-7": ["U7777777"],
        "invalid-char": ["z"]
    };
}

@test:Config {
    dataProvider: planarDataGen,
    groups: ["lexer"]
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

@test:Config {
    groups: ["lexer"]
}
function testSeparateInLineAfterPlanar() returns error? {
    LexerState state = setLexerString("planar space      ");
    check assertToken(state, PLANAR_CHAR, lexeme = "planar space");
    check assertToken(state, SEPARATION_IN_LINE);
}

@test:Config {
    dataProvider: blockScalarTokenDataGen,
    groups: ["lexer"]
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
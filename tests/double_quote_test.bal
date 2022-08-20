import ballerina/test;

@test:Config {
    dataProvider: escapedCharacterDataGen,
    groups: ["escaped"]
}
function testEscapedCharacterToken(string lexeme, string value) returns error? {
    Lexer lexer = setLexerString("\\" + lexeme, LEXER_DOUBLE_QUOTE);
    check assertToken(lexer, DOUBLE_QUOTE_CHAR, lexeme = value);
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
    groups: ["escaped"]
}
function testInvalidEscapedCharacter(string lexeme) {
    assertLexicalError("\\" + lexeme, state = LEXER_DOUBLE_QUOTE);
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
    dataProvider: doubleQuoteLineBreakDataGen
}
function testDoubleQuoteLineBreakEvent(string[] arr, string value) returns error? {
    check assertParsingEvent(arr, value);
}

function doubleQuoteLineBreakDataGen() returns map<[string[], string]> {
    return {
        "flow-folded": [["\"folded ", "to a space,   ", " ", "to a line feed\""], "folded to a space,\nto a line feed"],
        "escaped-line-break": [["\"folded to \\", " non-content\""], "folded to  non-content"],
        "first-line-space": [["\"space \""], "space "]
    };
}
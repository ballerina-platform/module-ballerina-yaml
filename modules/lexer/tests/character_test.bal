import ballerina/test;

@test:Config {
    dataProvider: indicatorDataGen,
    groups: ["character-productions", "lexer"]
}
function testIndicatorTokens(string lexeme, YAMLToken expectedToken) returns error? {
    LexerState state = setLexerString(lexeme);
    check assertToken(state, expectedToken);
}

function indicatorDataGen() returns map<[string, YAMLToken]> {
    return {
        "sequence-entry": ["-", SEQUENCE_ENTRY],
        "mapping-key": ["?", MAPPING_KEY],
        "mapping-value": [":", MAPPING_VALUE],
        "collection-entry": [",", SEPARATOR],
        "sequence-start": ["[", SEQUENCE_START],
        "sequence-end": ["]", SEQUENCE_END],
        "mapping-start": ["{", MAPPING_START],
        "folding": [">", FOLDED],
        "literal": ["|", LITERAL],
        "mapping-end": ["}", MAPPING_END],
        "directive-marker": ["---", DIRECTIVE_MARKER],
        "document-marker": ["...", DOCUMENT_MARKER]
    };
}

@test:Config {
    groups: ["lexer"]
}
function testAnchorToken() returns error? {
    LexerState state = setLexerString("&anchor value", LEXER_TAG_NODE);
    check assertToken(state, ANCHOR, lexeme = "anchor");
}

@test:Config {
    groups: ["lexer"]
}
function testAliasToken() returns error? {
    LexerState state = setLexerString("*anchor");
    check assertToken(state, ALIAS, lexeme = "anchor");
}

@test:Config {
    groups: ["lexer"]
}
function testSeparationSpacesToken() returns error? {
    LexerState state = setLexerString("  1");
    check assertToken(state, SEPARATION_IN_LINE);
    check assertToken(state, PLANAR_CHAR, lexeme = "1");
}

@test:Config {
    groups: ["lexer"]
}
function testEmptyLineToken() returns error? {
    LexerState state = setLexerString("");
    check assertToken(state, EMPTY_LINE);

    state = setLexerString(" ");
    check assertToken(state, EMPTY_LINE);
}

@test:Config {
    dataProvider: nodeTagDataGen
}
function testNodeTagToken(string line, string value) returns error? {
    LexerState state = setLexerString(line);
    check assertToken(state, TAG, lexeme = value);
}

function nodeTagDataGen() returns map<[string, string]> {
    return {
        "verbatim global": ["!<tag:yaml.org,2002:str>", "tag:yaml.org,2002:str"],
        "verbatim local": ["!<!bar> ", "!bar"],
        "non-specific tag": ["!", "!"]
    };
}

@test:Config {
    dataProvider: ambiguousTagDataGen
}
function testDetectingPrimaryOverNamed(string inputLine) returns error? {
    LexerState state = setLexerString(inputLine);
    check assertToken(state, TAG_HANDLE, lexeme = "!");
    check assertToken(state, TAG, lexeme = "primary");
}

function ambiguousTagDataGen() returns map<[string]> {
    return {
        "flow indicator at end": ["!primary]"],
        "whitespace at end": ["!primary "],
        "hexadecimal at end": ["!primar%79"],
        "hexadecimal at middle": ["!prim%61ry"],
        "hexadecimal at start": ["!%70rim%61ry"],
        "hexadecimal at multiple": ["!%70%72im%61r%79"],
        "end of line": ["!primary"]
    };
}

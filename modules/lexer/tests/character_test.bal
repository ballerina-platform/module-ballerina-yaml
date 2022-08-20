import ballerina/test;

@test:Config {
    dataProvider: indicatorDataGen,
    groups: ["character-productions", "lexer"]
}
function testIndicatorTokens(string inputLine, YAMLToken expectedToken) returns error? {
    LexerState state = setLexerString(inputLine);
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
    dataProvider: validTokenDataGen,
    groups: ["lexer"]
}
function testValidTokenInContext(string inputLine, YAMLToken expectedToken, Context context) returns error? {
    LexerState state = setLexerString(inputLine, context = context);
    check assertToken(state, expectedToken);
}

function validTokenDataGen() returns map<[string, YAMLToken, Context]> {
    return {
        "directive marker in double-quoted": ["---", DIRECTIVE_MARKER, LEXER_DOUBLE_QUOTE],
        "document marker in double-quoted": ["...", DOCUMENT_MARKER, LEXER_DOUBLE_QUOTE],
        "directive marker in single-quoted": ["---", DIRECTIVE_MARKER, LEXER_SINGLE_QUOTE],
        "document marker in single-quoted": ["...", DOCUMENT_MARKER, LEXER_SINGLE_QUOTE]
    };
}

@test:Config {
    groups: ["lexer"]
}
function testAnchorToken() returns error? {
    LexerState state = setLexerString("&anchor value", LEXER_NODE_PROPERTY);
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

@test:Config {
    dataProvider: invalidLexemeDataGen,
    groups: ["lexer"]
}
function testInvalidLexemeForToken(string inputLine, Context context) {
    assertLexicalError(inputLine, context = context);
}

function invalidLexemeDataGen() returns map<[string, Context]> {
    return {
        "hex in named tag handle": ["!named%61!", LEXER_TAG_HANDLE],
        "invalid reserve name": ["invalidcharacter", LEXER_RESERVED_DIRECTIVE],
        "invalid uri char": ["invalidcharacter", LEXER_TAG_PREFIX],
        "invalid unicode escape": ["invalid \\ud8000 hex", LEXER_DOUBLE_QUOTE],
        "invalid tag char": ["[invalid", LEXER_NODE_PROPERTY]
    };
}

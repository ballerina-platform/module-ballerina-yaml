import ballerina/test;

@test:Config {
    dataProvider: indicatorDataGen,
    groups: ["character-productions"]
}
function testIndicatorTokens(string lexeme, YAMLToken expectedToken) returns error? {
    Lexer lexer = setLexerString(lexeme);
    check assertToken(lexer, expectedToken);
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
        "mapping-end": ["}", MAPPING_END]
    };
}

@test:Config {}
function testAnchorToken() returns error? {
    Lexer lexer = setLexerString("&anchor value", LEXER_TAG_NODE);
    check assertToken(lexer, ANCHOR, lexeme = "anchor");
}

@test:Config {}
function testAliasToken() returns error? {
    Lexer lexer = setLexerString("*anchor");
    check assertToken(lexer, ALIAS, lexeme = "anchor");
}

@test:Config {}
function testSeparationSpacesToken() returns error? {
    Lexer lexer = setLexerString("  1");
    check assertToken(lexer, SEPARATION_IN_LINE);
    check assertToken(lexer, PLANAR_CHAR, lexeme = "1");
}

@test:Config {}
function testEmptyLineToken() returns error? {
    Lexer lexer = setLexerString("");
    check assertToken(lexer, EMPTY_LINE);

    lexer = setLexerString(" ");
    check assertToken(lexer, EMPTY_LINE);
}

@test:Config {
    dataProvider: lineFoldingDataGen
}
function testProcessLineFolding(string[] arr, string value) returns error? {
    check assertParsingEvent(arr, value);
}

function lineFoldingDataGen() returns map<[string[], string]> {
    return {
        "space": [["\"as", "space\""], "as space"],
        "space-empty": [["\"", "space\""], " space"]
    };
}

@test:Config {
    dataProvider: nodeTagDataGen
}
function testNodeTagToken(string line, string value) returns error? {
    Lexer lexer = setLexerString(line);
    check assertToken(lexer, TAG, lexeme = value);
}

function nodeTagDataGen() returns map<[string, string]> {
    return {
        "verbatim global": ["!<tag:yaml.org,2002:str>", "tag:yaml.org,2002:str"],
        "verbatim local": ["!<!bar> ", "!bar"],
        "non-specific tag": ["!", "!"]
    };
}

@test:Config {
    dataProvider: invalidNodeTagDataGen
}
function testInvalidNodeTagToken(string line, boolean isLexical) returns error? {
    check assertParsingError(line, isLexical);
}

function invalidNodeTagDataGen() returns map<[string, boolean]> {
    return {
        "verbatim primary": ["!<!>", true],
        "verbatim empty": ["!<>", true],
        "tag-shorthand no-suffix": ["!e!", false]
    };
}

@test:Config {
    dataProvider: tagShorthandDataGen
}
function testTagShorthandEvent(string line, string tagHandle, string tag) returns error? {
    check assertParsingEvent(line, tagHandle = tagHandle, tag = tag);
}

function tagShorthandDataGen() returns map<[string, string, string]> {
    return {
        "primary": ["!local value", "!", "local"],
        "secondary": ["!!str value", "!!", "str"],
        "named": ["!e!tag value", "!e!", "tag"],
        "escaped": ["!e!tag%21 value", "!e!", "tag!"],
        "double!": ["!%21 value", "!", "!"]
    };
}

@test:Config {
    dataProvider: invalidTagShorthandDataGen
}
function testInvalidTagShorthandEvent(string line, boolean isLexical) returns error? {
    check assertParsingError(line, isLexical);
}

function invalidTagShorthandDataGen() returns map<[string, boolean]> {
    return {
        "no suffix": ["!e! value", false],
        "terminating !": ["!e!tag! value", true]
    };
}

@test:Config {
    dataProvider: nodeSeparateDataGen
}
function testNodeSeparationEvent(string[] arr, string tagHandle) returns error? {
    check assertParsingEvent(arr, "value", "tag", tagHandle, "anchor");
}

function nodeSeparateDataGen() returns map<[string[], string]> {
    return {
        "single space": [["!tag &anchor value"], "!"],
        "verbatim tag": [["!<tag> &anchor value"], ""],
        "new line": [["!!tag", "&anchor value"], "!!"],
        "with comment": [["!tag #first-comment", "#second-comment", "&anchor value"], "!"],
        "anchor first": [["&anchor !tag value"], "!"]
    };
}

@test:Config {}
function testAliasEvent() returns error? {
    Parser parser = check new Parser(["*anchor"]);
    Event event = check parser.parse();

    test:assertEquals((<AliasEvent>event).alias, "anchor");
}

@test:Config {
    dataProvider: endEventDataGen
}
function testEndEvent(string line, EventType endType) returns error? {
    Parser parser = check new Parser([line]);
    Event event = check parser.parse();

    test:assertEquals((<EndEvent>event).endType, endType);
}

function endEventDataGen() returns map<[string, EventType]> {
    return {
        "end-sequence": ["]", SEQUENCE],
        "end-mapping": ["}", MAPPING],
        "end-document": ["...", DOCUMENT],
        "end-stream": ["", STREAM]
    };
}

@test:Config {
    dataProvider: startEventDataGen
}
function testStartEvent(string line, EventType eventType, string? anchor) returns error? {
    Parser parser = check new Parser([line]);
    Event event = check parser.parse();

    test:assertEquals((<StartEvent>event).startType, eventType);
    test:assertEquals((<StartEvent>event).anchor, anchor);
}

function startEventDataGen() returns map<[string, EventType, string?]> {
    return {
        "mapping-start with tag": ["&anchor {", MAPPING, "anchor"],
        "mapping-start": ["{", MAPPING, ()],
        "sequence-start with tag": ["&anchor [", SEQUENCE, "anchor"],
        "sequence-start": ["[", SEQUENCE, ()]
    };
}

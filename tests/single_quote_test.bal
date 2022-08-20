import ballerina/test;

@test:Config {
    dataProvider: singleQuoteDataGen
}
function testSingleQuoteEvent(string[] arr, string value) returns error? {
    check assertParsingEvent(arr, value);
}

function singleQuoteDataGen() returns map<[string[], string]> {
    return {
        "empty": [["''"], ""],
        "single-quote": [["''''"], "'"],
        "double-quote": [["''''''"], "''"],
        "multi-line": [["' 1st non-empty", "", " 2nd non-empty ", "3rd non-empty '"], " 1st non-empty\n2nd non-empty 3rd non-empty "]
    };
}

@test:Config {
    dataProvider: planarDataGen
}
function testPlanarToken(string line, string lexeme) returns error? {
    Lexer lexer = setLexerString(line);
    check assertToken(lexer, PLANAR_CHAR, lexeme = lexeme);
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
    Lexer lexer = setLexerString("planar space      ");
    check assertToken(lexer, PLANAR_CHAR, lexeme = "planar space");
    check assertToken(lexer, SEPARATION_IN_LINE);
}

@test:Config {}
function testMultilinePlanarEvent() returns error? {
    check assertParsingEvent(["1st non-empty", " ", " 2nd non-empty ", "  3rd non-empty"], "1st non-empty\n2nd non-empty 3rd non-empty");
}

@test:Config {
    dataProvider: flowKeyDataGen
}
function testFlowKeyEvent(string line, string? key, string? value) returns error? {
    Parser parser = check new Parser([line]);

    Event event = check parser.parse();
    test:assertEquals((<StartEvent>event).startType, MAPPING);

    event = check parser.parse();
    test:assertEquals((<ScalarEvent>event).value, key);

    event = check parser.parse();
    test:assertEquals((<ScalarEvent>event).value, value);
}

function flowKeyDataGen() returns map<[string, string?, string?]> {
    return {
        "yaml key": ["unquoted : \"value\"", "unquoted", "value"],
        "json-key yaml-node": ["'json-key':yaml", "json-key", "yaml"],
        "json-key json-node": ["'json-key':\"json\"", "json-key", "json"],
        "json-key with space value": ["'json-key': \"json\"", "json-key", "json"],
        "json-key with space key": ["'json-key' : \"json\"", "json-key", "json"],
        "explicit": ["{? explicit: value}", "explicit", "value"],
        "double mapping values": ["'json-key'::planar", "json-key", ":planar"],
        "no key": [": value", (), "value"]
    };
}

@test:Config {
    dataProvider: multipleMapEntriesDataGen
}
function testMultipleMapEntriesEvent(string[] arr, string?[] keys, string?[] values) returns error? {
    Parser parser = check new Parser(arr);

    Event event = check parser.parse();
    test:assertEquals((<StartEvent>event).startType, MAPPING);

    foreach int i in 0 ... values.length() - 1 {
        event = check parser.parse();
        test:assertEquals((<ScalarEvent>event).value, keys[i]);

        event = check parser.parse();
        test:assertEquals((<ScalarEvent>event).value, values[i]);
    }
}

function multipleMapEntriesDataGen() returns map<[string[], string?[], string?[]]> {
    return {
        "multiple values": [["{first: second ,", "third: forth"], ["first", "third"], ["second", "forth"]],
        "ends with comma": [["{first: second ,", "third: forth ,"], ["first", "third"], ["second", "forth"]],
        "multiline span": [["key : ", " ", "", " value"], ["key"], ["value"]]
    };
}

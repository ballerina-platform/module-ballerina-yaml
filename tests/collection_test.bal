import ballerina/test;

@test:Config {
    dataProvider: collectionDataGen
}
function testBlockCollectionEvents(string|string[] line, Event[] eventTree) returns error? {
    Parser parser = check new Parser((line is string) ? [line] : line);

    foreach Event item in eventTree {
        Event event = check parser.parse();
        test:assertEquals(event, item);
    }
}

function collectionDataGen() returns map<[string|string[], Event[]]> {
    return {
        "single element": ["- value", [{startType: SEQUENCE}, {value: "value"}]],
        "single character sequence": ["- a", [{startType: SEQUENCE}, {value: "a"}]],
        "compact sequence in-line": ["- - value", [{startType: SEQUENCE}, {startType: SEQUENCE}, {value: "value"}]],
        "empty sequence entry": ["- ", [{startType: SEQUENCE}, {endType: STREAM}]],
        "nested sequence": [["- ", " - value1", " - value2", "- value3"], [{startType: SEQUENCE}, {startType: SEQUENCE}, {value: "value1"}, {value: "value2"}, {endType: SEQUENCE}, {value: "value3"}]],
        "multiple end sequences": [["- ", " - value1", "   - value2", "- value3"], [{startType: SEQUENCE}, {startType: SEQUENCE}, {value: "value1"}, {startType: SEQUENCE}, {value: "value2"}, {endType: SEQUENCE}, {endType: SEQUENCE}, {value: "value3"}]],
        "differentiate planar value and key": [["first key: first line", " second line", "second key: value"], [{startType: MAPPING}, {value: "first key"}, {value: "first line second line"}, {value: "second key"}, {value: "value"}]],
        "escaping sequence with mapping": [["first:", " - ", "   - item", "second: value"], [{startType: MAPPING}, {value: "first"}, {startType: SEQUENCE}, {startType: SEQUENCE}, {value: "item"}, {endType: SEQUENCE}, {endType: SEQUENCE}, {value: "second"}, {value: "value"}]],
        "block sequence with starting anchor": [["- &anchor", " -"], [{startType: SEQUENCE}, {startType: SEQUENCE, anchor: "anchor"}]],
        "block sequence with starting tag": [["- !tag", " -"], [{startType: SEQUENCE}, {startType: SEQUENCE, tagHandle: "!", tag: "tag"}]],
        "block sequence with complete node properties": [["- !tag &anchor", " -"], [{startType: SEQUENCE}, {startType: SEQUENCE, tagHandle: "!", tag: "tag", anchor: "anchor"}]],
        "mapping scalars to sequences with same indent": [["key1: ", "- first", "- second", "key2:", "- third"], [{startType: MAPPING}, {value: "key1"}, {startType: SEQUENCE}, {value: "first"}, {value: "second"}, {endType: SEQUENCE}, {value: "key2"}, {startType: SEQUENCE}, {value: "third"}]],
        "mapping scalars to nested sequences with same indent": [["key1: ", "- first", "  - second", "key2: third"], [{startType: MAPPING}, {value: "key1"}, {startType: SEQUENCE}, {value: "first"}, {startType: SEQUENCE}, {value: "second"}, {endType: SEQUENCE}, {endType: SEQUENCE}, {value: "key2"}, {value: "third"}]],
        "mapping scalars to nested mappings with same indent": [["key1: ", "  key2: ", "  - sequence", "key3: mapping"], [{startType: MAPPING}, {value: "key1"}, {startType: MAPPING}, {value: "key2"}, {startType: SEQUENCE}, {value: "sequence"}, {endType: SEQUENCE}, {endType: MAPPING}, {value: "key3"}, {value: "mapping"}]],
        "mapping scalars to mapping sequence with same indent": [["key1: ", "- key2: first", "- second", "key3: third"], [{startType: MAPPING}, {value: "key1"}, {startType: SEQUENCE}, {startType: MAPPING}, {value: "key2"}, {value: "first"}, {endType: MAPPING}, {value: "second"}, {endType: SEQUENCE}, {value: "key3"}, {value: "third"}]],
        "escaping multiple mappings": [["first: ", "  second: ", "    third: ", "forth: value"], [{startType: MAPPING}, {value: "first"}, {startType: MAPPING}, {value: "second"}, {startType: MAPPING}, {value: "third"}, {endType: MAPPING}, {endType: MAPPING}, {value: "forth"}]],
        "empty value flow mapping with mapping value": ["{key: ,}", [{startType: MAPPING, flowStyle: true}, {value: "key"}, {value: ()}]]
    };
}

@test:Config {}
function testInvalidIndentCollection() returns error? {
    Parser parser = check new Parser(["- ", "  - value", " - value"]);

    Event event = check parser.parse();
    test:assertEquals((<StartEvent>event).startType, SEQUENCE);

    event = check parser.parse();
    test:assertEquals((<StartEvent>event).startType, SEQUENCE);

    Event|error err = parser.parse();
    test:assertTrue(err is LexicalError);
}

@test:Config {}
function testBlockMapAndSequenceAtSameIndent() returns error? {
    check assertParsingError(["- seq", "map: value"], true, 2);
}

@test:Config {}
function testIndentationOfBlockSequence() returns error? {
    Parser parser = check new Parser(["-", "  -", "     -", "-"]);
    [int, int][] indentMapping = [[0, 1], [2, 2], [5, 3], [0, 1]];

    foreach int i in 0 ... 3 {
        _ = check parser.parse();
        test:assertEquals(parser.lexer.indent, indentMapping[i][0]);
        test:assertEquals(parser.lexer.indents.length(), indentMapping[i][1]);
    }
}

@test:Config {}
function testIndentationOfBlockMapping() returns error? {
    string[] lines = ["first:", "  second:", "     third:", "forth:"];
    [int, int][] indentMapping = [[0, 1], [2, 2], [5, 3], [0, 1]];

    Lexer lexer = new Lexer();
    foreach int i in 0 ... 3 {
        lexer.line = lines[i];
        lexer.index = 0;
        Token token = check lexer.getToken();

        while token.token != PLANAR_CHAR {
            token = check lexer.getToken();
        }

        test:assertEquals(lexer.indent, indentMapping[i][0]);
        test:assertEquals(lexer.indents.length(), indentMapping[i][1]);
    }
}

@test:Config {
    dataProvider: explicitKeysDataGen
}
function testExplicitKey(string|string[] line, Event[] eventTree) returns error? {
    Parser parser = check new Parser((line is string) ? [line] : line);

    foreach Event item in eventTree {
        Event event = check parser.parse();
        test:assertEquals(event, item);
    }
}

function explicitKeysDataGen() returns map<[string|string[], Event[]]> {
    return {
        "single-line key": ["{? explicit: value}", [{startType: MAPPING, flowStyle: true}, {value: "explicit"}, {value: "value"}]],
        "multiline key": [["{? first", " second", ": value"], [{startType: MAPPING, flowStyle: true}, {value: "first second"}, {value: "value"}]],
        "block planar key": [["? first", " second", ": value"], [{startType: MAPPING}, {value: "first second"}, {value: "value"}]],
        "block folded scalar key": [["? >-", " first", " second", ": value"], [{startType: MAPPING}, {value: "first second"}, {value: "value"}]],
        "empty key in flow mapping": ["{? : value}", [{startType: MAPPING, flowStyle: true}, {value: ()}, {value: "value"}]],
        "only explicit key in flow mapping": ["{? }", [{startType: MAPPING, flowStyle: true}, {value: ()}, {value: ()}]]
    };
}

@test:Config {
    dataProvider: invalidKeyDataGen
}
function testInvalidBlockKeys(string|string[] lines, boolean isLexical) returns error? {
    check assertParsingError(lines, isLexical);
}

function invalidKeyDataGen() returns map<[string|string[], boolean]> {
    return {
        "explicit key and mapping value without indent": [["? first", " second", " : value"], true],
        "explicit key without indent": [["? first", "second", ": value"], true],
        "multiline implicit key": [["first", "second", " : value"], false]
    };
}

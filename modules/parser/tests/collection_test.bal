import ballerina/test;
import yaml.event;
import yaml.lexer;

@test:Config {
    dataProvider: collectionDataGen
}
function testBlockCollectionEvents(string|string[] line, event:Event[] eventTree) returns error? {
    ParserState state = check new((line is string) ? [line] : line);

    foreach event:Event item in eventTree {
        event:Event event = check parse(state);
        test:assertEquals(event, item);
    }
}

function collectionDataGen() returns map<[string|string[], event:Event[]]> {
    return {
        "single element": ["- value", [{startType: event:SEQUENCE}, {value: "value"}]],
        "single character sequence": ["- a", [{startType: event:SEQUENCE}, {value: "a"}]],
        "compact sequence in-line": ["- - value", [{startType: event:SEQUENCE}, {startType: event:SEQUENCE}, {value: "value"}]],
        "empty sequence entry": ["- ", [{startType: event:SEQUENCE}, {endType: event:STREAM}]],
        "nested sequence": [["- ", " - value1", " - value2", "- value3"], [{startType: event:SEQUENCE}, {startType: event:SEQUENCE}, {value: "value1"}, {value: "value2"}, {endType: event:SEQUENCE}, {value: "value3"}]],
        "multiple end sequences": [["- ", " - value1", "   - value2", "- value3"], [{startType: event:SEQUENCE}, {startType: event:SEQUENCE}, {value: "value1"}, {startType: event:SEQUENCE}, {value: "value2"}, {endType: event:SEQUENCE}, {endType: event:SEQUENCE}, {value: "value3"}]],
        "differentiate planar value and key": [["first key: first line", " second line", "second key: value"], [{startType: event:MAPPING}, {value: "first key"}, {value: "first line second line"}, {value: "second key"}, {value: "value"}]],
        "escaping sequence with mapping": [["first:", " - ", "   - item", "second: value"], [{startType: event:MAPPING}, {value: "first"}, {startType: event:SEQUENCE}, {startType: event:SEQUENCE}, {value: "item"}, {endType: event:SEQUENCE}, {endType: event:SEQUENCE}, {value: "second"}, {value: "value"}]],
        "block sequence with starting anchor": [["- &anchor", " -"], [{startType: event:SEQUENCE}, {startType: event:SEQUENCE, anchor: "anchor"}]],
        "block sequence with starting tag": [["- !tag", " -"], [{startType: event:SEQUENCE}, {startType: event:SEQUENCE, tagHandle: "!", tag: "tag"}]],
        "block sequence with complete node properties": [["- !tag &anchor", " -"], [{startType: event:SEQUENCE}, {startType: event:SEQUENCE, tagHandle: "!", tag: "tag", anchor: "anchor"}]],
        "mapping scalars to sequences with same indent": [["key1: ", "- first", "- second", "key2:", "- third"], [{startType: event:MAPPING}, {value: "key1"}, {startType: event:SEQUENCE}, {value: "first"}, {value: "second"}, {endType: event:SEQUENCE}, {value: "key2"}, {startType: event:SEQUENCE}, {value: "third"}]],
        "mapping scalars to nested sequences with same indent": [["key1: ", "- first", "  - second", "key2: third"], [{startType: event:MAPPING}, {value: "key1"}, {startType: event:SEQUENCE}, {value: "first"}, {startType: event:SEQUENCE}, {value: "second"}, {endType: event:SEQUENCE}, {endType: event:SEQUENCE}, {value: "key2"}, {value: "third"}]],
        "mapping scalars to nested mappings with same indent": [["key1: ", "  key2: ", "  - sequence", "key3: mapping"], [{startType: event:MAPPING}, {value: "key1"}, {startType: event:MAPPING}, {value: "key2"}, {startType: event:SEQUENCE}, {value: "sequence"}, {endType: event:SEQUENCE}, {endType: event:MAPPING}, {value: "key3"}, {value: "mapping"}]],
        "mapping scalars to mapping sequence with same indent": [["key1: ", "- key2: first", "- second", "key3: third"], [{startType: event:MAPPING}, {value: "key1"}, {startType: event:SEQUENCE}, {startType: event:MAPPING}, {value: "key2"}, {value: "first"}, {endType: event:MAPPING}, {value: "second"}, {endType: event:SEQUENCE}, {value: "key3"}, {value: "third"}]],
        "escaping multiple mappings": [["first: ", "  second: ", "    third: ", "forth: value"], [{startType: event:MAPPING}, {value: "first"}, {startType: event:MAPPING}, {value: "second"}, {startType: event:MAPPING}, {value: "third"}, {endType: event:MAPPING}, {endType: event:MAPPING}, {value: "forth"}]],
        "empty value flow mapping with mapping value": ["{key: ,}", [{startType: event:MAPPING, flowStyle: true}, {value: "key"}, {value: ()}]]
    };
}

@test:Config {}
function testInvalidIndentCollection() returns error? {
    ParserState state = check new(["- ", "  - value", " - value"]);

    event:Event event = check parse(state);
    test:assertEquals((<event:StartEvent>event).startType, event:SEQUENCE);

    event = check parse(state);
    test:assertEquals((<event:StartEvent>event).startType, event:SEQUENCE);

    event:Event|error err = parse(state);
    test:assertTrue(err is lexer:LexicalError);
}

@test:Config {}
function testBlockMapAndSequenceAtSameIndent() returns error? {
    check assertParsingError(["- seq", "map: value"], true, 2);
}

// @test:Config {}
// function testIndentationOfBlockSequence() returns error? {
//     ParserState state = check new(["-", "  -", "     -", "-"]);
//     [int, int][] indentMapping = [[0, 1], [2, 2], [5, 3], [0, 1]];

//     foreach int i in 0 ... 3 {
//         _ = check parse(state);
//         test:assertEquals(state.lexerState.indent, indentMapping[i][0]);
//         test:assertEquals(state.lexerState.indents.length(), indentMapping[i][1]);
//     }
// }

@test:Config {
    dataProvider: explicitKeysDataGen
}
function testExplicitKey(string|string[] line, event:Event[] eventTree) returns error? {
    ParserState state = check new((line is string) ? [line] : line);

    foreach event:Event item in eventTree {
        event:Event event = check parse(state);
        test:assertEquals(event, item);
    }
}

function explicitKeysDataGen() returns map<[string|string[], event:Event[]]> {
    return {
        "single-line key": ["{? explicit: value}", [{startType: event:MAPPING, flowStyle: true}, {value: "explicit"}, {value: "value"}]],
        "multiline key": [["{? first", " second", ": value"], [{startType: event:MAPPING, flowStyle: true}, {value: "first second"}, {value: "value"}]],
        "block planar key": [["? first", " second", ": value"], [{startType: event:MAPPING}, {value: "first second"}, {value: "value"}]],
        "block folded scalar key": [["? >-", " first", " second", ": value"], [{startType: event:MAPPING}, {value: "first second"}, {value: "value"}]],
        "empty key in flow mapping": ["{? : value}", [{startType: event:MAPPING, flowStyle: true}, {value: ()}, {value: "value"}]],
        "only explicit key in flow mapping": ["{? }", [{startType: event:MAPPING, flowStyle: true}, {value: ()}, {value: ()}]]
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

import ballerina/test;
import yaml.common;

@test:Config {
    dataProvider: doubleQuoteLineBreakDataGen,
    groups: ["parser"]
}
function testDoubleQuoteLineBreakEvent(string[] arr, string value) returns error? {
    check assertParsingEvent(arr, value);
}

function doubleQuoteLineBreakDataGen() returns map<[string[], string]> {
    return {
        "flow-folded": [["\"folded ", "to a space,   ", " ", "to a line feed\""], "folded to a space,\nto a line feed"],
        "escaped line-break": [["\"folded to \\", " non-content\""], "folded to non-content"],
        "escaped empty-line": [["\"some \\", "  ", "value\""], "some \nvalue"],
        "first-line-space": [["\"space \""], "space "]
    };
}

@test:Config {
    dataProvider: singleQuoteDataGen,
    groups: ["parser"]
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
    groups: ["parser"]
}
function testMultilinePlanarEvent() returns error? {
    check assertParsingEvent(["1st non-empty", " ", " 2nd non-empty ", "  3rd non-empty"], "1st non-empty\n2nd non-empty 3rd non-empty");
}

@test:Config {
    dataProvider: flowKeyDataGen,
    groups: ["parser"]
}
function testFlowKeyEvent(string line, string? key, string? value) returns error? {
    ParserState state = check new ([line]);

    common:Event event = check parse(state);
    test:assertEquals((<common:StartEvent>event).startType, common:MAPPING);

    event = check parse(state);
    test:assertEquals((<common:ScalarEvent>event).value, key);

    event = check parse(state);
    test:assertEquals((<common:ScalarEvent>event).value, value);
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
    dataProvider: multipleMapEntriesDataGen,
    groups: ["parser"]
}
function testMultipleMapEntriesEvent(string[] arr, string?[] keys, string?[] values) returns error? {
    ParserState state = check new (arr);

    common:Event event = check parse(state);
    test:assertEquals((<common:StartEvent>event).startType, common:MAPPING);

    foreach int i in 0 ... values.length() - 1 {
        event = check parse(state);
        test:assertEquals((<common:ScalarEvent>event).value, keys[i]);

        event = check parse(state);
        test:assertEquals((<common:ScalarEvent>event).value, values[i]);
    }
}

function multipleMapEntriesDataGen() returns map<[string[], string?[], string?[]]> {
    return {
        "ends with comma": [["{first: second ,", "third: forth ,"], ["first", "third"], ["second", "forth"]],
        "anchors in mapping": [["&a a: b", "c: &d d"], ["a", "c"], ["b", "d"]],
        "tags in mapping": [["!a a: b", "c: !d d"], ["a", "c"], ["b", "d"]],
        "quotes in mapping": [["!a 'a': b", "c: !d 'd'"], ["a", "c"], ["b", "d"]],
        "multiline span": [["key : ", " ", "", " value"], ["key"], ["value"]]
    };
}

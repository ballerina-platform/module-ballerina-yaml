import ballerina/test;
import yaml.common;
import yaml.lexer;

@test:Config {
    groups: ["parser"]
}
function testInvalidIndentCollection() returns error? {
    ParserState state = check new (["- ", "  - value", " - value"]);

    common:Event event = check parse(state);
    test:assertEquals((<common:StartEvent>event).startType, common:SEQUENCE);

    event = check parse(state);
    test:assertEquals((<common:StartEvent>event).startType, common:SEQUENCE);

    common:Event|error err = parse(state);
    test:assertTrue(err is lexer:LexicalError);
}

@test:Config {
    groups: ["parser"]
}
function testBlockMapAndSequenceAtSameIndent() returns error? {
    check assertParsingError(["- seq", "map: value"], true, 2);
}

@test:Config {
    dataProvider: explicitKeysDataGen,
    groups: ["parser"]
}
function testExplicitKey(string|string[] line, common:Event[] eventTree) returns error? {
    ParserState state = check new ((line is string) ? [line] : line);

    foreach common:Event item in eventTree {
        common:Event event = check parse(state);
        test:assertEquals(event, item);
    }
}

function explicitKeysDataGen() returns map<[string|string[], common:Event[]]> {
    return {
        "single-line key": [
            "{? explicit: value}",
            [{startType: common:MAPPING, flowStyle: true}, {value: "explicit"}, {value: "value"}]
        ],
        "block planar key": [
            ["? first", " second", ": value"],
            [{startType: common:MAPPING}, {value: "first second"}, {value: "value"}]
        ],
        "block folded scalar key": [
            ["? >-", " first", " second", ": value"],
            [{startType: common:MAPPING}, {value: "first second"}, {value: "value"}]
        ],
        "empty key in flow mapping": [
            "{? : value}",
            [{startType: common:MAPPING, flowStyle: true}, {value: ()}, {value: "value"}]
        ],
        "only explicit key in flow mapping": [
            "{? }",
            [{startType: common:MAPPING, flowStyle: true}, {value: ()}, {value: ()}]
        ]
    };
}

@test:Config {
    dataProvider: collectionDataGen,
    groups: ["parser"]
}
function testBlockCollectionEvents(string|string[] line, common:Event[] eventTree) returns error? {
    ParserState state = check new ((line is string) ? [line] : line);

    foreach common:Event item in eventTree {
        common:Event event = check parse(state);
        test:assertEquals(event, item);
    }
}

function collectionDataGen() returns map<[string|string[], common:Event[]]> {
    return {
        "single element": [
            "- value",
            [
                {startType: common:SEQUENCE},
                {value: "value"}
            ]
        ],
        "single character sequence": [
            "- a",
            [
                {startType: common:SEQUENCE},
                {value: "a"}
            ]
        ],
        "compact sequence in-line": [
            "- - value",
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE},
                {value: "value"}
            ]
        ],
        "empty sequence entry": [
            "- ",
            [
                {startType: common:SEQUENCE},
                {endType: common:STREAM}
            ]
        ],
        "nested sequence": [
            ["- ", " - value1", " - value2", "- value3"],
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE},
                {value: "value3"}
            ]
        ],
        "multiple end sequences": [
            ["- ", " - value1", "   - value2", "- value3"],
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE},
                {value: "value1 - value2"},
                {endType: common:SEQUENCE},
                {value: "value3"}
            ]
        ],
        "differentiate planar value and key": [
            ["first key: first line", " second line", "second key: value"],
            [
                {startType: common:MAPPING},
                {value: "first key"},
                {value: "first line second line"},
                {value: "second key"},
                {value: "value"}
            ]
        ],
        "escaping sequence with mapping": [
            ["first:", " - ", "   - item", "second: value"],
            [
                {startType: common:MAPPING},
                {value: "first"},
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE},
                {value: "item"},
                {endType: common:SEQUENCE},
                {endType: common:SEQUENCE},
                {value: "second"},
                {value: "value"}
            ]
        ],
        "block sequence with starting anchor": [
            ["- &anchor", " -"],
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE, anchor: "anchor"}
            ]
        ],
        "block sequence with starting tag": [
            ["- !tag", " -"],
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE, tag: "!tag"}
            ]
        ],
        "block sequence with complete node properties": [
            ["- !tag &anchor", " -"],
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE, tag: "!tag", anchor: "anchor"}
            ]
        ],
        "mapping scalars to sequences with same indent": [
            ["key1: ", "- first", "- second", "key2:", "- third"],
            [
                {startType: common:MAPPING},
                {value: "key1"},
                {startType: common:SEQUENCE},
                {value: "first"},
                {value: "second"},
                {endType: common:SEQUENCE},
                {value: "key2"},
                {startType: common:SEQUENCE},
                {value: "third"}
            ]
        ],
        "mapping scalars to nested sequences with same indent": [
            ["key1: ", "- ", "  - value", "key2: third"],
            [
                {startType: common:MAPPING},
                {value: "key1"},
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE},
                {value: "value"},
                {endType: common:SEQUENCE},
                {endType: common:SEQUENCE},
                {value: "key2"},
                {value: "third"}
            ]
        ],
        "mapping scalars to nested mappings with same indent": [
            ["key1: ", "  key2: ", "  - sequence", "key3: mapping"],
            [
                {startType: common:MAPPING},
                {value: "key1"},
                {startType: common:MAPPING},
                {value: "key2"},
                {startType: common:SEQUENCE},
                {value: "sequence"},
                {endType: common:SEQUENCE},
                {endType: common:MAPPING},
                {value: "key3"},
                {value: "mapping"}
            ]
        ],
        "mapping scalars to mapping sequence with same indent": [
            ["key1: ", "- key2: first", "- second", "key3: third"],
            [
                {startType: common:MAPPING},
                {value: "key1"},
                {startType: common:SEQUENCE},
                {startType: common:MAPPING},
                {value: "key2"},
                {value: "first"},
                {endType: common:MAPPING},
                {value: "second"},
                {endType: common:SEQUENCE},
                {value: "key3"},
                {value: "third"}
            ]
        ],
        "escaping multiple mappings": [
            ["first: ", "  second: ", "    third: ", "forth: value"],
            [
                {startType: common:MAPPING},
                {value: "first"},
                {startType: common:MAPPING},
                {value: "second"},
                {startType: common:MAPPING},
                {value: "third"},
                {endType: common:MAPPING},
                {endType: common:MAPPING},
                {value: "forth"}
            ]
        ],
        "anchoring nested map": [
            ["a: &anchor", "  b: value"],
            [
                {startType: common:MAPPING},
                {value: "a"},
                {startType: common:MAPPING, anchor: "anchor"},
                {value: "b"},
                {value: "value"}
            ]
        ]
    };
}

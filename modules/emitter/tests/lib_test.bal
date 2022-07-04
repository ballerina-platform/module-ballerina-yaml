import ballerina/test;
import yaml.common;
import yaml.schema;

string yamlStr = string `${schema:defaultGlobalTagHandle}str`;
string yamlInt = string `${schema:defaultGlobalTagHandle}int`;

@test:Config {
    dataProvider: simpleEventDataGen,
    groups: ["emitter"]
}
function testWritingSimpleEvent(common:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check getEmittedOutput(events);
    test:assertEquals(output, expectedOutput);
}

function simpleEventDataGen() returns map<[common:Event[], string[]]> {
    return {
        "empty block sequence": [[{startType: common:SEQUENCE}], ["-"]],
        "empty flow sequence": [[{startType: common:SEQUENCE, flowStyle: true}, {endType: common:SEQUENCE}], ["[]"]],
        "empty flow mapping": [[{startType: common:MAPPING, flowStyle: true}, {endType: common:MAPPING}], ["{}"]],
        "single block sequence entry": [
            [
                {startType: common:SEQUENCE},
                {value: "value"}
            ],
            ["- value"]
        ],
        "single block mapping entry": [
            [
                {startType: common:MAPPING},
                {value: "key"},
                {value: "value"}
            ],
            ["key: value"]
        ],
        "block sequence": [
            [
                {startType: common:SEQUENCE},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE}
            ],
            ["- value1", "- value2"]
        ],
        "block mappings": [
            [
                {startType: common:MAPPING},
                {value: "key1"},
                {value: "value1"},
                {value: "key2"},
                {value: "value2"}
            ],
            ["key1: value1", "key2: value2"]
        ],
        "block sequence nested under block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE},
                {value: "value"},
                {endType: common:SEQUENCE},
                {endType: common:SEQUENCE}
            ],
            ["-", "  - value"]
        ],
        "block sequence nested under block mapping": [
            [
                {startType: common:MAPPING},
                {value: "parentKey"},
                {startType: common:SEQUENCE},
                {value: "value1"},
                {value: "value2"}
            ],
            ["parentKey:", "- value1", "- value2"]
        ],
        "block mapping nested under block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:MAPPING},
                {value: "key1"},
                {value: "value1"},
                {value: "key2"},
                {value: "value2"}
            ],
            ["-", "  key1: value1", "  key2: value2"]
        ],
        "block mapping nested under block mapping": [
            [
                {startType: common:MAPPING},
                {value: "parentKey"},
                {startType: common:MAPPING},
                {value: "childKey"},
                {value: "value"}
            ],
            ["parentKey:", "  childKey: value"]
        ],
        "flow sequence nested under block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE}
            ],
            ["- [value1, value2]"]
        ],
        "flow sequence nested under block mapping": [
            [
                {startType: common:MAPPING},
                {value: "key"},
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE}
            ],
            ["key: [value1, value2]"]
        ],
        "flow sequence nested under flow sequence": [
            [
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value"},
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value"},
                {endType: common:SEQUENCE},
                {endType: common:SEQUENCE}
            ],
            ["[value, [value]]"]
        ],
        "flow sequence nested under flow mapping": [
            [
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE},
                {endType: common:MAPPING}
            ],
            ["{key: [value1, value2]}"]
        ],
        "flow mapping nested under block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: "value"},
                {endType: common:MAPPING}
            ],
            ["- {key: value}"]
        ],
        "flow mapping nested under block mapping": [
            [
                {startType: common:MAPPING},
                {value: "key"},
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: "value"},
                {endType: common:MAPPING}
            ],
            ["key: {key: value}"]
        ],
        "flow mapping nested under flow sequence": [
            [
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value"},
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: "value"},
                {endType: common:MAPPING},
                {endType: common:SEQUENCE}
            ],
            ["[value, {key: value}]"]
        ],
        "flow mapping nested under flow mapping": [
            [
                {startType: common:MAPPING, flowStyle: true},
                {value: "parentKey"},
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: "value"},
                {endType: common:MAPPING},
                {endType: common:MAPPING}
            ],
            ["{parentKey: {key: value}}"]
        ],
        "write only custom tags": [
            [
                {startType: common:SEQUENCE},
                {value: "custom value", tag: "!custom"},
                {value: "string value", tag: yamlStr},
                {endType: common:SEQUENCE}
            ],
            ["- !custom custom value", "- string value"]
        ],
        "single value": [[{value: "value"}], ["value"]]
    };
}

@test:Config {
    groups: ["emitter"]
}
function testMultipleRootEventsForOneDocument() returns error? {
    string[]|EmittingError output = getEmittedOutput([{value: "first root"}, {value: "second root"}]);
    test:assertTrue(output is EmittingError);
}

@test:Config {
    dataProvider: canonicalDataGen,
    groups: ["emitter"]
}
function testWritingInCanonical(common:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check getEmittedOutput(events, canonical = true);
    test:assertEquals(output, expectedOutput);
}

function canonicalDataGen() returns map<[common:Event[], string[]]> {
    return {
        "flow sequence": [
            [
                {startType: common:SEQUENCE, tag: "!custom", flowStyle: true},
                {value: "a", tag: yamlStr},
                {value: "1", tag: yamlInt},
                {endType: common:SEQUENCE}
            ],
            ["!custom [!!str a, !!int 1]"]
        ],
        "flow mapping": [
            [
                {startType: common:MAPPING, tag: "!custom", flowStyle: true},
                {value: "a", tag: yamlStr},
                {value: "1", tag: yamlInt},
                {endType: common:MAPPING}
            ],
            ["!custom {!!str a: !!int 1}"]
        ],
        "block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE, tag: "!custom"},
                {value: "a", tag: yamlStr},
                {value: "1", tag: yamlInt},
                {endType: common:SEQUENCE},
                {endType: common:SEQUENCE}
            ],
            ["- !custom", "  - !!str a", "  - !!int 1"]
        ],
        "empty block sequence": [
            [
                {startType: common:SEQUENCE, tag: "!custom"},
                {endType: common:SEQUENCE}
            ],
            ["- !custom"]
        ],
        "block mapping": [
            [
                {startType: common:MAPPING},
                {value: "a", tag: yamlStr},
                {startType: common:MAPPING, tag: "!custom"},
                {value: "b", tag: yamlStr},
                {value: "1", tag: yamlInt},
                {endType: common:MAPPING},
                {endType: common:MAPPING}
            ],
            ["!!str a: !custom", "  !!str b: !!int 1"]
        ],
        "global tag scalar": [[{value: "1", tag: yamlInt}], ["!!int 1"]],
        "local tag scalar": [[{value: "1", tag: "!digit"}], ["!digit 1"]],
        "verbatim tag scalar": [[{value: "1", tag: "verbatim-tag"}], ["!<verbatim-tag> 1"]],
        "no tag scalar": [[{value: "1"}], ["1"]]
    };
}

@test:Config {
    groups: ["emitter"]
}
function testWriteStream() returns error? {
    string[] output = check getEmittedOutput([{value: "1", tag: yamlInt}, {value: "2", tag: yamlInt}], isStream = true);
    test:assertEquals(output, ["1", "---", "2", "---"]);
}

@test:Config {
    dataProvider: invalidEventTreeDataGen
}
function test(common:Event[] inputEventTree) returns error? {
    string[]|EmittingError output = getEmittedOutput(inputEventTree);
    test:assertTrue(output is EmittingError);
}

function invalidEventTreeDataGen() returns map<[common:Event[]]> {
    return {
        "ending a flow style sequence with }": [[{startType: common:SEQUENCE, flowStyle: true}, {endType: common:MAPPING}]],
        "not ending a flow style sequence": [[{startType: common:SEQUENCE, flowStyle: true}]],
        "ending a block style sequence with }": [[{startType: common:SEQUENCE}, {endType: common:MAPPING}]],
        "ending a flow style mapping with ]": [[{startType: common:MAPPING, flowStyle: true}, {endType: common:SEQUENCE}]],
        "not ending a flow style mapping": [[{startType: common:MAPPING, flowStyle: true}]],
        "ending a block style mapping with ]": [[{startType: common:MAPPING}, {endType: common:SEQUENCE}]]
    };
}

@test:Config {
    groups: ["emitter"]
}
function testReduceCustomTagHandle() returns error? {
    string[] output = check getEmittedOutput([{value: "value", tag: "org.custom.schema:scalar"}], {"!custom!": "org.custom.schema:"});
    test:assertEquals(output, ["!custom!scalar value"]);
}

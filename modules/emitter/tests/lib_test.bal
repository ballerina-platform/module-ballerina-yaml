import ballerina/test;
import yaml.common;
import yaml.schema;

string yamlStr = string `${schema:defaultGlobalTagHandle}str`;
string yamlInt = string `${schema:defaultGlobalTagHandle}int`;

@test:Config {
    dataProvider: simpleEventDataGen
}
function testWritingSimpleEvent(common:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check emit(events, 2, false, {}, false);
    test:assertEquals(output, expectedOutput);
}

function simpleEventDataGen() returns map<[common:Event[], string[]]> {
    return {
        "empty block sequence": [[{startType: common:SEQUENCE}], ["-"]],
        "empty flow sequence": [[{startType: common:SEQUENCE, flowStyle: true}, {endType: common:SEQUENCE}], ["[]"]],
        "block sequence": [[{startType: common:SEQUENCE}, {value: "value1"}, {value: "value2"}, {endType: common:SEQUENCE}], ["- value1", "- value2"]],
        "indented block sequence": [[{startType: common:SEQUENCE}, {startType: common:SEQUENCE}, {value: "value"}, {endType: common:SEQUENCE}, {endType: common:SEQUENCE}], ["-", "  - value"]],
        "single block value": [[{startType: common:MAPPING}, {value: "key"}, {value: "value"}], ["key: value"]],
        "multiple block mappings": [[{startType: common:MAPPING}, {value: "key1"}, {value: "value1"}, {value: "key2"}, {value: "value2"}], ["key1: value1", "key2: value2"]],
        "indented block mapping": [[{startType: common:MAPPING}, {value: "parentKey"}, {startType: common:MAPPING}, {value: "childKey"}, {value: "value"}], ["parentKey:", "  childKey: value"]],
        "indented block sequence under mapping": [[{startType: common:MAPPING}, {value: "parentKey"}, {startType: common:SEQUENCE}, {value: "value1"}, {value: "value2"}], ["parentKey:", "- value1", "- value2"]],
        "indented block mapping under sequence": [[{startType: common:SEQUENCE}, {startType: common:MAPPING}, {value: "key1"}, {value: "value1"}, {value: "key2"}, {value: "value2"}], ["-", "  key1: value1", "  key2: value2"]],
        "block sequence flow sequence": [[{startType: common:SEQUENCE}, {startType: common:SEQUENCE, flowStyle: true}, {value: "value1"}, {value: "value2"}, {endType: common:SEQUENCE}], ["- [value1, value2]"]],
        "block sequence flow mapping": [[{startType: common:SEQUENCE}, {startType: common:MAPPING, flowStyle: true}, {value: "key"}, {value: "value"}, {endType: common:MAPPING}], ["- {key: value}"]],
        "nested flow sequence": [[{startType: common:SEQUENCE, flowStyle: true}, {value: "value"}, {startType: common:SEQUENCE, flowStyle: true}, {value: "value"}, {endType: common:SEQUENCE}, {endType: common:SEQUENCE}], ["[value, [value]]"]],
        "nested flow mapping": [[{startType: common:MAPPING, flowStyle: true}, {value: "parentKey"}, {startType: common:MAPPING, flowStyle: true}, {value: "key"}, {value: "value"}, {endType: common:MAPPING}, {endType: common:MAPPING}], ["{parentKey: {key: value}}"]],
        "single value": [[{value: "value"}], ["value"]]
    };
}

@test:Config {}
function testMultipleRootEventsForOneDocument() returns error? {
    string[]|EmittingError output = emit([{value: "first root"}, {value: "second root"}], 2, false, {}, false);
    test:assertTrue(output is EmittingError);
}

@test:Config {
    dataProvider: canonicalDataGen
}
function testWritingInCanonical(common:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check emit(events, 2, true, {}, false);
    test:assertEquals(output, expectedOutput);
}

function canonicalDataGen() returns map<[common:Event[], string[]]> {
    return {
        "flow sequence": [[{startType: common:SEQUENCE, tag: "!custom", flowStyle: true}, {value: "a", tag: yamlStr}, {value: "1", tag: yamlInt}, {endType: common:SEQUENCE}], ["!custom [!!str a, !!int 1]"]],
        "flow mapping": [[{startType: common:MAPPING, tag: "!custom", flowStyle: true}, {value: "a", tag: yamlStr}, {value: "1", tag: yamlInt}, {endType: common:MAPPING}], ["!custom {!!str a: !!int 1}"]],
        "block sequence": [[{startType: common:SEQUENCE}, {startType: common:SEQUENCE, tag: "!custom"}, {value: "a", tag: yamlStr}, {value: "1", tag: yamlInt}, {endType: common:SEQUENCE}, {endType: common:SEQUENCE}], ["- !custom", "  - !!str a", "  - !!int 1"]],
        "empty block sequence": [[{startType: common:SEQUENCE, tag: "!custom"}, {endType: common:SEQUENCE}], ["- !custom"]],
        "block mapping": [[{startType: common:MAPPING}, {value: "a", tag: yamlStr}, {startType: common:MAPPING, tag: "!custom"}, {value: "b", tag: yamlStr}, {value: "1", tag: yamlInt}, {endType: common:MAPPING}, {endType: common:MAPPING}], ["!!str a: !custom", "  !!str b: !!int 1"]],
        "global tag scalar": [[{value: "1", tag: yamlInt}], ["!!int 1"]],
        "local tag scalar": [[{value: "1", tag: "!digit"}], ["!digit 1"]]
    };
}

@test:Config {}
function testWriteStream() returns error? {
    string[] output = check emit([{value: "1", tag: yamlInt}, {value: "2", tag: yamlInt}], 2, false, {}, true);
    test:assertEquals(output, ["1", "...", "2", "..."]);
}

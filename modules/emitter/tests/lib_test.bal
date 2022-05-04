import ballerina/test;
import yaml.event;
import yaml.schema;

string yamlStr = string `${schema:defaultGlobalTagHandle}str`;
string yamlInt = string `${schema:defaultGlobalTagHandle}int`;

@test:Config {
    dataProvider: simpleEventDataGen
}
function testWritingSimpleEvent(event:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check emit(events, 2, false, {}, false);
    test:assertEquals(output, expectedOutput);
}

function simpleEventDataGen() returns map<[event:Event[], string[]]> {
    return {
        "empty block sequence": [[{startType: event:SEQUENCE}], ["-"]],
        "empty flow sequence": [[{startType: event:SEQUENCE, flowStyle: true}, {endType: event:SEQUENCE}], ["[]"]],
        "block sequence": [[{startType: event:SEQUENCE}, {value: "value1"}, {value: "value2"}, {endType: event:SEQUENCE}], ["- value1", "- value2"]],
        "indented block sequence": [[{startType: event:SEQUENCE}, {startType: event:SEQUENCE}, {value: "value"}, {endType: event:SEQUENCE}, {endType: event:SEQUENCE}], ["-", "  - value"]],
        "single block value": [[{startType: event:MAPPING}, {value: "key"}, {value: "value"}], ["key: value"]],
        "multiple block mappings": [[{startType: event:MAPPING}, {value: "key1"}, {value: "value1"}, {value: "key2"}, {value: "value2"}], ["key1: value1", "key2: value2"]],
        "indented block mapping": [[{startType: event:MAPPING}, {value: "parentKey"}, {startType: event:MAPPING}, {value: "childKey"}, {value: "value"}], ["parentKey:", "  childKey: value"]],
        "indented block sequence under mapping": [[{startType: event:MAPPING}, {value: "parentKey"}, {startType: event:SEQUENCE}, {value: "value1"}, {value: "value2"}], ["parentKey:", "- value1", "- value2"]],
        "indented block mapping under sequence": [[{startType: event:SEQUENCE}, {startType: event:MAPPING}, {value: "key1"}, {value: "value1"}, {value: "key2"}, {value: "value2"}], ["-", "  key1: value1", "  key2: value2"]],
        "block sequence flow sequence": [[{startType: event:SEQUENCE}, {startType: event:SEQUENCE, flowStyle: true}, {value: "value1"}, {value: "value2"}, {endType: event:SEQUENCE}], ["- [value1, value2]"]],
        "block sequence flow mapping": [[{startType: event:SEQUENCE}, {startType: event:MAPPING, flowStyle: true}, {value: "key"}, {value: "value"}, {endType: event:MAPPING}], ["- {key: value}"]],
        "nested flow sequence": [[{startType: event:SEQUENCE, flowStyle: true}, {value: "value"}, {startType: event:SEQUENCE, flowStyle: true}, {value: "value"}, {endType: event:SEQUENCE}, {endType: event:SEQUENCE}], ["[value, [value]]"]],
        "nested flow mapping": [[{startType: event:MAPPING, flowStyle: true}, {value: "parentKey"}, {startType: event:MAPPING, flowStyle: true}, {value: "key"}, {value: "value"}, {endType: event:MAPPING}, {endType: event:MAPPING}], ["{parentKey: {key: value}}"]],
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
function testWritingInCanonical(event:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check emit(events, 2, true, {}, false);
    test:assertEquals(output, expectedOutput);
}

function canonicalDataGen() returns map<[event:Event[], string[]]> {
    return {
        "flow sequence": [[{startType: event:SEQUENCE, tag: "!custom", flowStyle: true}, {value: "a", tag: yamlStr}, {value: "1", tag: yamlInt}, {endType: event:SEQUENCE}], ["!custom [!!str a, !!int 1]"]],
        "flow mapping": [[{startType: event:MAPPING, tag: "!custom", flowStyle: true}, {value: "a", tag: yamlStr}, {value: "1", tag: yamlInt}, {endType: event:MAPPING}], ["!custom {!!str a: !!int 1}"]],
        "block sequence": [[{startType: event:SEQUENCE}, {startType: event:SEQUENCE, tag: "!custom"}, {value: "a", tag: yamlStr}, {value: "1", tag: yamlInt}, {endType: event:SEQUENCE}, {endType: event:SEQUENCE}], ["- !custom", "  - !!str a", "  - !!int 1"]],
        "empty block sequence": [[{startType: event:SEQUENCE, tag: "!custom"}, {endType: event:SEQUENCE}], ["- !custom"]],
        "block mapping": [[{startType: event:MAPPING}, {value: "a", tag: yamlStr}, {startType: event:MAPPING, tag: "!custom"}, {value: "b", tag: yamlStr}, {value: "1", tag: yamlInt}, {endType: event:MAPPING}, {endType: event:MAPPING}], ["!!str a: !custom", "  !!str b: !!int 1"]],
        "global tag scalar": [[{value: "1", tag: yamlInt}], ["!!int 1"]],
        "local tag scalar": [[{value: "1", tag: "!digit"}], ["!digit 1"]]
    };
}

@test:Config {}
function testWriteStream() returns error? {
    string[] output = check emit([{value: "1", tag: yamlInt}, {value: "2", tag: yamlInt}], 2, false, {}, true);
    test:assertEquals(output, ["1", "...", "2", "..."]);
}

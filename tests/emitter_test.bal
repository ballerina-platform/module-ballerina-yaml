import ballerina/test;

@test:Config {
    dataProvider: simpleEventDataGen
}
function testWritingSimpleEvent(Event[] events, string[] expectedOutput) returns error? {
    string[] output = check emit(events);
    test:assertEquals(output, expectedOutput);
}

function simpleEventDataGen() returns map<[Event[], string[]]> {
    return {
        "empty block sequence": [[{startType: SEQUENCE}], ["-"]],
        "empty flow sequence": [[{startType: SEQUENCE, flowStyle: true}], ["[]"]],
        "block sequence": [[{startType: SEQUENCE}, {value: "value1"}, {value: "value2"}, {endType: SEQUENCE}], ["- value1", "- value2"]],
        "indented block sequence": [[{startType: SEQUENCE}, {startType: SEQUENCE}, {value: "value"}, {endType: SEQUENCE}, {endType: SEQUENCE}], ["-", "  - value"]],
        "single block value": [[{startType: MAPPING}, {value: "key"}, {value: "value"}], ["key: value"]],
        "multiple block mappings": [[{startType: MAPPING}, {value: "key1"}, {value: "value1"}, {value: "key2"}, {value: "value2"}], ["key1: value1", "key2: value2"]],
        "indented block mapping": [[{startType: MAPPING}, {value: "parentKey"}, {startType: MAPPING}, {value: "childKey"}, {value: "value"}], ["parentKey: ", "  childKey: value"]],
        "indented block sequence under mapping": [[{startType: MAPPING}, {value: "parentKey"}, {startType: SEQUENCE}, {value: "value1"}, {value: "value2"}], ["parentKey: ", "- value1", "- value2"]],
        "indented block mapping under sequence": [[{startType: SEQUENCE},{startType: MAPPING},  {value: "key1"}, {value: "value1"}, {value: "key2"}, {value: "value2"}], ["-", "  key1: value1", "  key2: value2"]],
        "block sequence flow sequence": [[{startType: SEQUENCE}, {startType: SEQUENCE, flowStyle: true}, {value: "value1"}, {value: "value2"}], ["- [value1, value2]"]],
        "block sequence flow mapping": [[{startType: SEQUENCE}, {startType: MAPPING, flowStyle: true}, {value: "key"}, {value: "value"}], ["- {key: value}"]],
        "nested flow sequence": [[{startType: SEQUENCE, flowStyle: true}, {value: "value"}, {startType: SEQUENCE, flowStyle: true}, {value: "value"}], ["[value, [value]]"]],
        "nested flow mapping": [[{startType: MAPPING, flowStyle: true}, {value: "parentKey"}, {startType: MAPPING, flowStyle: true}, {value: "key"}, {value: "value"}], ["{parentKey: {key: value}}"]],
        "single value": [[{value: "value"}], ["value"]]
    };
}

import ballerina/test;
import yaml.event;

@test:Config {
    dataProvider: simpleEventDataGen
}
function testWritingSimpleEvent(event:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check emit(events, 2);
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
        "indented block mapping": [[{startType: event:MAPPING}, {value: "parentKey"}, {startType: event:MAPPING}, {value: "childKey"}, {value: "value"}], ["parentKey: ", "  childKey: value"]],
        "indented block sequence under mapping": [[{startType: event:MAPPING}, {value: "parentKey"}, {startType: event:SEQUENCE}, {value: "value1"}, {value: "value2"}], ["parentKey: ", "- value1", "- value2"]],
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
    string[]|EmittingError output = emit([{value: "first root"}, {value: "second root"}], 2);
    test:assertTrue(output is EmittingError);
}

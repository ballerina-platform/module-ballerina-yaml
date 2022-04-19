import ballerina/test;

@test:Config {
    dataProvider: serializingEventDataGen
}
function testGenerateSerializingEvent(json structure, Event[] assertingEvents) returns error? {
    Serializer serializer = new Serializer();
    Event[] events = check serializer.serialize(structure);

    test:assertEquals(events, assertingEvents);
}

function serializingEventDataGen() returns map<[json, Event[]]> {
    return {
        "empty array": [[], [{startType: SEQUENCE}, {endType: SEQUENCE}]],
        "single element array": [["value"], [{startType: SEQUENCE}, {value: "value"}, {endType: SEQUENCE}]],
        "multiple elements array": [["value1", "value2"], [{startType: SEQUENCE}, {value: "value1"}, {value: "value2"}, {endType: SEQUENCE}]],
        "nested array": [[["value"]], [{startType: SEQUENCE}, {startType: SEQUENCE, flowStyle: true}, {value: "value"}, {endType: SEQUENCE}, {endType: SEQUENCE}]],
        "empty mapping": [{}, [{startType: MAPPING}, {endType: MAPPING}]],
        "single element mapping": [{"key": "value"}, [{startType: MAPPING}, {value: "key"}, {value: "value"}, {endType: MAPPING}]],
        "multiple elements mapping": [{"key1": "value1", "key2": "value2"}, [{startType: MAPPING}, {value: "key1"}, {value: "value1"}, {value: "key2"}, {value: "value2"}, {endType: MAPPING}]],
        "single element": ["value", [{value: "value"}]]
    };
}

@test:Config {}
function testSwitchFlowStyleUponBlockLevel() returns error? {
    Serializer serializer = new Serializer(blockLevel = 1);
    Event[] events = check serializer.serialize([["value"]]);

    test:assertFalse((<StartEvent>events[0]).flowStyle);
    test:assertTrue((<StartEvent>events[1]).flowStyle);
}
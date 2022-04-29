import ballerina/test;
import yaml.schema;
import yaml.event;

@test:Config {
    dataProvider: serializingEventDataGen
}
function testGenerateSerializingEvent(json structure, event:Event[] assertingEvents) returns error? {
    event:Event[] events = check serialize(structure, {}, 1);
    test:assertEquals(events, assertingEvents);
}

function serializingEventDataGen() returns map<[json, event:Event[]]> {
    return {
        "empty array": [[], [{startType: event:SEQUENCE}, {endType: event:SEQUENCE}]],
        "single element array": [["value"], [{startType: event:SEQUENCE}, {value: "value"}, {endType: event:SEQUENCE}]],
        "multiple elements array": [["value1", "value2"], [{startType: event:SEQUENCE}, {value: "value1"}, {value: "value2"}, {endType: event:SEQUENCE}]],
        "nested array": [[["value"]], [{startType: event:SEQUENCE}, {startType: event:SEQUENCE, flowStyle: true}, {value: "value"}, {endType: event:SEQUENCE}, {endType: event:SEQUENCE}]],
        "empty mapping": [{}, [{startType: event:MAPPING}, {endType: event:MAPPING}]],
        "single element mapping": [{"key": "value"}, [{startType: event:MAPPING}, {value: "key"}, {value: "value"}, {endType: event:MAPPING}]],
        "multiple elements mapping": [{"key1": "value1", "key2": "value2"}, [{startType: event:MAPPING}, {value: "key1"}, {value: "value1"}, {value: "key2"}, {value: "value2"}, {endType: event:MAPPING}]],
        "single element": ["value", [{value: "value"}]]
    };
}

@test:Config {
    dataProvider: keySerializeDataGen
}
function testTagInSerializedEvent(json structure, event:Event[] assertingEvents) returns error? {
    event:Event[] events = check serialize(structure, schema:getJsonSchemaTags(), 1);
    test:assertEquals(events, assertingEvents);
}

function keySerializeDataGen() returns map<[json, event:Event[]]> {
    return {
        "integer": [1, [{value: "1", tag: "tag:yaml.org,2002:int"}]],
        "float": [1.1, [{value: "1.1", tag: "tag:yaml.org,2002:float"}]]
    };
}

@test:Config {}
function testSwitchFlowStyleUponBlockLevel() returns error? {
    event:Event[] events = check serialize([["value"]], {}, 1);

    test:assertFalse((<event:StartEvent>events[0]).flowStyle);
    test:assertTrue((<event:StartEvent>events[1]).flowStyle);
}

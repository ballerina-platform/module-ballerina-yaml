import ballerina/test;
import yaml.schema;
import yaml.event;

type RGB [int, int, int];

function constructRGB(json data) returns json|schema:TypeError {
    RGB|error value = data.cloneWithType();

    if value is error {
        return error("Invalid shape for RGB");
    }

    foreach int index in value {
        if index > 255 || index < 0 {
            return error("One RGB value must be between 0-255");
        }
    }

    return value;
}

string yamlSeq = string `${schema:defaultGlobalTagHandle}seq`;
string yamlMap = string `${schema:defaultGlobalTagHandle}map`;
string yamlStr = string `${schema:defaultGlobalTagHandle}str`;

@test:Config {
    dataProvider: serializingEventDataGen
}
function testGenerateSerializingEvent(json structure, event:Event[] assertingEvents) returns error? {
    event:Event[] events = check serialize(structure, {}, 1, "\"", false);
    test:assertEquals(events, assertingEvents);
}

function serializingEventDataGen() returns map<[json, event:Event[]]> {
    return {
        "empty array": [[], [{startType: event:SEQUENCE, tag: yamlSeq}, {endType: event:SEQUENCE}]],
        "single element array": [["value"], [{startType: event:SEQUENCE, tag: yamlSeq}, {value: "value", tag: yamlStr}, {endType: event:SEQUENCE}]],
        "multiple elements array": [["value1", "value2"], [{startType: event:SEQUENCE, tag: yamlSeq}, {value: "value1", tag: yamlStr}, {value: "value2", tag: yamlStr}, {endType: event:SEQUENCE}]],
        "nested array": [[["value"]], [{startType: event:SEQUENCE, tag: yamlSeq}, {startType: event:SEQUENCE, tag: yamlSeq, flowStyle: true}, {value: "value", tag: yamlStr}, {endType: event:SEQUENCE}, {endType: event:SEQUENCE}]],
        "empty mapping": [{}, [{startType: event:MAPPING, tag: yamlMap}, {endType: event:MAPPING}]],
        "single element mapping": [{"key": "value"}, [{startType: event:MAPPING, tag: yamlMap}, {value: "key", tag: yamlStr}, {value: "value", tag: yamlStr}, {endType: event:MAPPING}]],
        "multiple elements mapping": [{"key1": "value1", "key2": "value2"}, [{startType: event:MAPPING, tag: yamlMap}, {value: "key1", tag: yamlStr}, {value: "value1", tag: yamlStr}, {value: "key2", tag: yamlStr}, {value: "value2", tag: yamlStr}, {endType: event:MAPPING}]],
        "single element": ["value", [{value: "value", tag: yamlStr}]]
    };
}

@test:Config {
    dataProvider: keySerializeDataGen
}
function testTagInSerializedEvent(json structure, event:Event[] assertingEvents) returns error? {
    event:Event[] events = check serialize(structure, schema:getCoreSchemaTags(), 1, "\"", false);
    test:assertEquals(events, assertingEvents);
}

function keySerializeDataGen() returns map<[json, event:Event[]]> {
    return {
        "integer": [1, [{value: "1", tag: string `${schema:defaultGlobalTagHandle}int`}]],
        "negative integer": [-1, [{value: "-1", tag: string `${schema:defaultGlobalTagHandle}int`}]],
        "float": [1.1, [{value: "1.1", tag: "tag:yaml.org,2002:float"}]],
        "boolean": [true, [{value: "true", tag: "tag:yaml.org,2002:bool"}]],
        "null": [(), [{value: "", tag: "tag:yaml.org,2002:null"}]],
        "float infinity": ['float:Infinity, [{value: ".inf", tag: "tag:yaml.org,2002:float"}]],
        "float negative infinity": [-'float:Infinity, [{value: "-.inf", tag: "tag:yaml.org,2002:float"}]],
        "float not a number": ['float:NaN, [{value: ".nan", tag: "tag:yaml.org,2002:float"}]]
    };
}

@test:Config {}
function testCustomTag() returns error? {
    map<schema:YAMLTypeConstructor> tagHandles = schema:getJsonSchemaTags();
    tagHandles["!rgb"] = {
        kind: schema:SEQUENCE,
        construct: constructRGB,
        identity: function(json data) returns boolean {
            RGB|error output = data.cloneWithType();
            return output is RGB;
        },
        represent: function(json data) returns string => data.toString()
    };

    RGB testingInput = [123, 12, 32];
    event:Event[] events = check serialize(testingInput, tagHandles, 1, "\"", false);
    event:Event expectedEvent = {startType: event:SEQUENCE, tag: "!rgb"};

    test:assertEquals(events[0], expectedEvent);
}

@test:Config {}
function testSwitchFlowStyleUponBlockLevel() returns error? {
    event:Event[] events = check serialize([["value"]], {}, 1, "\"", false);

    test:assertFalse((<event:StartEvent>events[0]).flowStyle);
    test:assertTrue((<event:StartEvent>events[1]).flowStyle);
}

@test:Config {
    dataProvider: invalidPlanarDataGen
}
function testQuotesForInvalidPlanarChar(string line) returns error? {
    event:Event[] events = check serialize(line, {}, 1, "\"", false);
    event:Event expectedEvent = {value: string `"${line}"`, tag: yamlStr};
    test:assertEquals(events[0], expectedEvent);
}

function invalidPlanarDataGen() returns map<[string]> {
    return {
        "comment": [" #"],
        "explicit key": ["? "],
        "sequence entry": ["- "],
        "mapping value": [": "],
        "flow indicator": ["}a"]
    };
}

@test:Config {}
function testSingleQuotesOption() returns error? {
    event:Event[] events = check serialize("? value", {}, 1, "'", false);
    event:Event expectedEvent = {value: "'? value'", tag: yamlStr};
    test:assertEquals(events[0], expectedEvent);
}

@test:Config {}
function testEnforceQuotesOption() returns error? {
    event:Event[] events = check serialize("value", {}, 1, "\"", true);
    event:Event expectedEvent = {value: "\"value\"", tag: yamlStr};
    test:assertEquals(events[0], expectedEvent);
}

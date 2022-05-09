import ballerina/test;
import yaml.schema;
import yaml.common;

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
function testGenerateSerializingEvent(json structure, common:Event[] assertingEvents) returns error? {
    common:Event[] events = check serialize(structure, {}, 1, "\"", false);
    test:assertEquals(events, assertingEvents);
}

function serializingEventDataGen() returns map<[json, common:Event[]]> {
    return {
        "empty array": [[], [{startType: common:SEQUENCE, tag: yamlSeq}, {endType: common:SEQUENCE}]],
        "single element array": [["value"], [{startType: common:SEQUENCE, tag: yamlSeq}, {value: "value", tag: yamlStr}, {endType: common:SEQUENCE}]],
        "multiple elements array": [["value1", "value2"], [{startType: common:SEQUENCE, tag: yamlSeq}, {value: "value1", tag: yamlStr}, {value: "value2", tag: yamlStr}, {endType: common:SEQUENCE}]],
        "nested array": [[["value"]], [{startType: common:SEQUENCE, tag: yamlSeq}, {startType: common:SEQUENCE, tag: yamlSeq, flowStyle: true}, {value: "value", tag: yamlStr}, {endType: common:SEQUENCE}, {endType: common:SEQUENCE}]],
        "empty mapping": [{}, [{startType: common:MAPPING, tag: yamlMap}, {endType: common:MAPPING}]],
        "single element mapping": [{"key": "value"}, [{startType: common:MAPPING, tag: yamlMap}, {value: "key", tag: yamlStr}, {value: "value", tag: yamlStr}, {endType: common:MAPPING}]],
        "multiple elements mapping": [{"key1": "value1", "key2": "value2"}, [{startType: common:MAPPING, tag: yamlMap}, {value: "key1", tag: yamlStr}, {value: "value1", tag: yamlStr}, {value: "key2", tag: yamlStr}, {value: "value2", tag: yamlStr}, {endType: common:MAPPING}]],
        "single element": ["value", [{value: "value", tag: yamlStr}]]
    };
}

@test:Config {
    dataProvider: keySerializeDataGen
}
function testTagInSerializedEvent(json structure, common:Event[] assertingEvents) returns error? {
    common:Event[] events = check serialize(structure, schema:getCoreSchemaTags(), 1, "\"", false);
    test:assertEquals(events, assertingEvents);
}

function keySerializeDataGen() returns map<[json, common:Event[]]> {
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
        identity: schema:generateIdentityFunction(RGB),
        represent: function(json data) returns string => data.toString()
    };

    RGB testingInput = [123, 12, 32];
    common:Event[] events = check serialize(testingInput, tagHandles, 1, "\"", false);
    common:Event expectedEvent = {startType: common:SEQUENCE, tag: "!rgb"};

    test:assertEquals(events[0], expectedEvent);
}

@test:Config {}
function testSwitchFlowStyleUponBlockLevel() returns error? {
    common:Event[] events = check serialize([["value"]], {}, 1, "\"", false);

    test:assertFalse((<common:StartEvent>events[0]).flowStyle);
    test:assertTrue((<common:StartEvent>events[1]).flowStyle);
}

@test:Config {
    dataProvider: invalidPlanarDataGen
}
function testQuotesForInvalidPlanarChar(string line) returns error? {
    common:Event[] events = check serialize(line, {}, 1, "\"", false);
    common:Event expectedEvent = {value: string `"${line}"`, tag: yamlStr};
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
    common:Event[] events = check serialize("? value", {}, 1, "'", false);
    common:Event expectedEvent = {value: "'? value'", tag: yamlStr};
    test:assertEquals(events[0], expectedEvent);
}

@test:Config {}
function testEnforceQuotesOption() returns error? {
    common:Event[] events = check serialize("value", {}, 1, "\"", true);
    common:Event expectedEvent = {value: "\"value\"", tag: yamlStr};
    test:assertEquals(events[0], expectedEvent);
}

// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ballerina/test;
import yaml.schema;
import yaml.common;

string yamlSeq = string `${schema:defaultGlobalTagHandle}seq`;
string yamlMap = string `${schema:defaultGlobalTagHandle}map`;
string yamlStr = string `${schema:defaultGlobalTagHandle}str`;

@test:Config {
    dataProvider: serializingEventDataGen,
    groups: ["serializer"]
}
function testGenerateSerializingEvent(json structure, common:Event[] assertingEvents) returns error? {
    common:Event[] events = check getSerializedEvents(structure);
    test:assertEquals(events, assertingEvents);
}

function serializingEventDataGen() returns map<[json, common:Event[]]> {
    return {
        "empty array": [[], [{startType: common:SEQUENCE, tag: yamlSeq, flowStyle: true}, {endType: common:SEQUENCE}]],
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
    dataProvider: keySerializeDataGen,
    groups: ["serializer"]
}
function testTagInSerializedEvent(json structure, common:Event[] assertingEvents) returns error? {
    common:Event[] events = check getSerializedEvents(structure, tagSchema = schema:getCoreSchemaTags());
    test:assertEquals(events, assertingEvents);
}

function keySerializeDataGen() returns map<[json, common:Event[]]> {
    return {
        "integer": [1, [{value: "1", tag: string `${schema:defaultGlobalTagHandle}int`}]],
        "negative integer": [-1, [{value: "-1", tag: string `${schema:defaultGlobalTagHandle}int`}]],
        "float": [1.1, [{value: "1.1", tag: "tag:yaml.org,2002:float"}]],
        "boolean": [true, [{value: "true", tag: "tag:yaml.org,2002:bool"}]],
        "null": [(), [{value: "", tag: "tag:yaml.org,2002:null"}]],
        "float infinity": [float:Infinity, [{value: ".inf", tag: "tag:yaml.org,2002:float"}]],
        "float negative infinity": [-float:Infinity, [{value: "-.inf", tag: "tag:yaml.org,2002:float"}]],
        "float not a number": [float:NaN, [{value: ".nan", tag: "tag:yaml.org,2002:float"}]]
    };
}

@test:Config {
    groups: ["serializer"]
}
function testSwitchFlowStyleUponBlockLevel() returns error? {
    common:Event[] events = check getSerializedEvents([["value"]]);

    test:assertFalse((<common:StartEvent>events[0]).flowStyle);
    test:assertTrue((<common:StartEvent>events[1]).flowStyle);
}

@test:Config {
    dataProvider: invalidPlanarDataGen,
    groups: ["serializer"]
}
function testQuotesForInvalidPlanarChar(string line) returns error? {
    common:Event[] events = check getSerializedEvents(line);
    common:Event expectedEvent = {value: string `"${line}"`, tag: yamlStr};
    test:assertEquals(events[0], expectedEvent);
}

function invalidPlanarDataGen() returns map<[string]> {
    return {
        "comment": [" # comment"],
        "explicit key": ["? "],
        "sequence entry": ["- "],
        "mapping value": [": "],
        "flow indicator": ["}a"],
        "alias": ["*/*"],
        "collect-entry": [", "],
        "anchor": ["&anchor"],
        "tag": ["!tag"],
        "directive": ["%YAML 1.2"]
    };
}

@test:Config {
    dataProvider: scalarWithNewLinesDataGen,
    groups: ["serializer"]
}
function testScalarWithNewLines(json line, string[] expectedOutputs) returns error? {
    common:Event[] events = check getSerializedEvents(line);
    int index = 0;
    foreach common:Event event in events {
        if event is common:ScalarEvent {
            test:assertEquals(event.value, string `"${expectedOutputs[index]}"`);
            index += 1;
        }
    }
    test:assertEquals(index, expectedOutputs.length());
}

function scalarWithNewLinesDataGen()returns map<[json, string[]]> =>
    {
        "simple scalar": ["first\nsecond", ["first\\nsecond"]],
        "sequence": [[["first\nsecond"], ["first\nsecond\n\nthird"]], ["first\\nsecond", "first\\nsecond\\n\\nthird"]],
        "nested sequence": [[[["first\nsecond"]]], ["first\\nsecond"]],
        "mapping": [{"key\nline": "first\nsecond"}, ["key\\nline", "first\\nsecond"]],
        "nested mapping": [{"key\nline": {"nested\nline": "first\nsecond"}}, ["key\\nline", "nested\\nline", "first\\nsecond"]]
    };

@test:Config {
    groups: ["serializer"]
}
function testSingleQuotesOption() returns error? {
    common:Event[] events = check getSerializedEvents("? value", delimiter = "'");

    common:Event expectedEvent = {value: "'? value'", tag: yamlStr};
    test:assertEquals(events[0], expectedEvent);
}

@test:Config {
    groups: ["serializer"]
}
function testEnforceQuotesOption() returns error? {
    common:Event[] events = check getSerializedEvents("value", forceQuotes = true);

    common:Event expectedEvent = {value: "\"value\"", tag: yamlStr};
    test:assertEquals(events[0], expectedEvent);
}

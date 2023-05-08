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

import ballerina/file;
import ballerina/io;
import ballerina/test;

@test:Config {
    groups: ["api"],
    enable: false
}
function testReadTOMLString() returns error? {
    string input = string `
        outer:
          inner: {outer: inner}
        seq:
          - - [[nested, sequence]]
        int: 1
        bool: true
        float: 1.1`;
    json output = check readString(input);

    test:assertEquals(output, {
        "outer": {
            "inner": {
                "outer": "inner"
            }
        },
        "seq": [[[["nested", "sequence"]]]],
        "int": 1,
        "bool": true,
        "float": <decimal>1.1
    });
}

@test:Config {
    groups: ["api"]
}
function testReadTOMLFile() returns error? {
    check io:fileWriteString("input.yaml", "bool: true\nint: 1");
    json output = check readFile("input.yaml");
    test:assertEquals(output, {"bool": true, "int": 1});
    check file:remove("input.yaml");
}

@test:Config {
    groups: ["api"]
}
function testWriteTOMLString() returns error? {
    string[] output = check writeString({"key": "value"});
    test:assertEquals(output[0], "key: value");
}

@test:Config {
    groups: ["api"]
}
function testWriteTOMLFile() returns error? {
    check writeFile("output.toml", {"outer": {"inner": "value"}}, blockLevel = 2, indentationPolicy = 2);
    string[] output = check io:fileReadLines("output.toml");
    test:assertEquals(output, ["outer:", "  inner: value"]);
    check file:remove("output.toml");
}

@test:Config {
    dataProvider: yamlSchemaDataGen,
    groups: ["api"],
    enable: false
}
function testReadYAMLSchema(YAMLSchema schema, json expectedOutput) returns error? {
    string input = string `
        int: 1
        bool: true
        nan: .nan`;
    json output = check readString(input, schema = schema);

    test:assertEquals(output, expectedOutput);
}

function yamlSchemaDataGen() returns map<[YAMLSchema, json]> {
    return {
        "core schema": [CORE_SCHEMA, {"int": 1, "bool": true, "nan": float:NaN}],
        "json schema": [JSON_SCHEMA, {"int": 1, "bool": true, "nan": ".nan"}],
        "failsafe schema": [FAILSAFE_SCHEMA, {"int": "1", "bool": "true", "nan": ".nan"}]
    };
}

@test:Config {}
function testInvalidAttemptWriteToDirectory() returns error? {
    check file:createDir("output");
    FileError? err = openFile("output");
    test:assertTrue(err is FileError);
    check file:remove("output");
}

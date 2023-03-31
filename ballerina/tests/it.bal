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

YAMLType[] customYamlTypes = [];
map<FailSafeSchema> customTags = {
    "!": STRING,
    "!foo": STRING,
    "tag:example.com,2000:app/foo": STRING,
    "tag:yaml.org,2002:set": MAPPING,
    "tag:yaml.org,2002:binary": STRING,
    "!my-light": STRING,
    "!local": STRING,
    "!bar": STRING,
    "tag:clarkevans.com,2002:shape": SEQUENCE,
    "tag:clarkevans.com,2002:circle": MAPPING,
    "tag:clarkevans.com,2002:line": MAPPING,
    "tag:clarkevans.com,2002:label": MAPPING,
    "tag:yaml.org,2002:omap": SEQUENCE,
    "tag:example.com,2000:app/int": STRING,
    "tag:example.com,2000:app/tag!": STRING,
    "tag:example.com,2011:A": STRING
};

@test:BeforeSuite
function initYamlCustomeTypes() {
    customTags.entries().forEach(function([string, FailSafeSchema] entry) {
        customYamlTypes.push({
            tag: entry[0],
            ballerinaType: string,
            kind: entry[1],
            construct: function(json data) returns json => data,
            represent: function(json data) returns string => data.toString()
        });
    });
}

@test:Config {
    dataProvider: yamlDataGen,
    enable: false
}
function testYAMLIntegrationTest(string filePath, json expectedOutput, boolean isStream, boolean isError) returns error? {
    json|Error output = readFile(filePath, yamlTypes = customYamlTypes, isStream = isStream);
    if isError {
        test:assertTrue(output is Error);
    } else {
        test:assertEquals(output, expectedOutput);
    }
}

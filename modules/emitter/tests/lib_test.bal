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
import yaml.common;
import yaml.schema;

string yamlStr = string `${schema:defaultGlobalTagHandle}str`;
string yamlInt = string `${schema:defaultGlobalTagHandle}int`;
string yamlNull = string `${schema:defaultGlobalTagHandle}null`;
string yamlSeq = string `${schema:defaultGlobalTagHandle}seq`;
string yamlMap = string `${schema:defaultGlobalTagHandle}map`;

@test:Config {
    dataProvider: simpleEventDataGen,
    groups: ["emitter"]
}
function testWritingSimpleEvent(common:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check getEmittedOutput(events);
    test:assertEquals(output, expectedOutput);
}

function simpleEventDataGen() returns map<[common:Event[], string[]]> {
    return {
        "empty flow sequence": [[{startType: common:SEQUENCE, flowStyle: true}, {endType: common:SEQUENCE}], ["[]"]],
        "empty flow mapping": [[{startType: common:MAPPING, flowStyle: true}, {endType: common:MAPPING}], ["{}"]],
        "single block sequence entry": [
            [
                {startType: common:SEQUENCE},
                {value: "value"}
            ],
            ["- value"]
        ],
        "single block mapping entry": [
            [
                {startType: common:MAPPING},
                {value: "key"},
                {value: "value"}
            ],
            ["key: value"]
        ],
        "block sequence": [
            [
                {startType: common:SEQUENCE},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE}
            ],
            ["- value1", "- value2"]
        ],
        "block mappings": [
            [
                {startType: common:MAPPING},
                {value: "key1"},
                {value: "value1"},
                {value: "key2"},
                {value: "value2"}
            ],
            ["key1: value1", "key2: value2"]
        ],
        "block sequence nested under block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE},
                {value: "value"},
                {endType: common:SEQUENCE},
                {endType: common:SEQUENCE}
            ],
            ["-", "  - value"]
        ],
        "block sequence nested under block mapping": [
            [
                {startType: common:MAPPING},
                {value: "parentKey"},
                {startType: common:SEQUENCE},
                {value: "value1"},
                {value: "value2"}
            ],
            ["parentKey:", "- value1", "- value2"]
        ],
        "block mapping nested under block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:MAPPING},
                {value: "key1"},
                {value: "value1"},
                {value: "key2"},
                {value: "value2"}
            ],
            ["-", "  key1: value1", "  key2: value2"]
        ],
        "block mapping nested under block mapping": [
            [
                {startType: common:MAPPING},
                {value: "parentKey"},
                {startType: common:MAPPING},
                {value: "childKey"},
                {value: "value"}
            ],
            ["parentKey:", "  childKey: value"]
        ],
        "flow sequence nested under block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE}
            ],
            ["- [value1, value2]"]
        ],
        "flow sequence nested under block mapping": [
            [
                {startType: common:MAPPING},
                {value: "key"},
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE}
            ],
            ["key: [value1, value2]"]
        ],
        "flow sequence nested under flow sequence": [
            [
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value"},
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value"},
                {endType: common:SEQUENCE},
                {endType: common:SEQUENCE}
            ],
            ["[value, [value]]"]
        ],
        "flow sequence nested under flow mapping": [
            [
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value1"},
                {value: "value2"},
                {endType: common:SEQUENCE},
                {endType: common:MAPPING}
            ],
            ["{key: [value1, value2]}"]
        ],
        "flow mapping nested under block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: "value"},
                {endType: common:MAPPING}
            ],
            ["- {key: value}"]
        ],
        "flow mapping nested under block mapping": [
            [
                {startType: common:MAPPING},
                {value: "key"},
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: "value"},
                {endType: common:MAPPING}
            ],
            ["key: {key: value}"]
        ],
        "flow mapping nested under flow sequence": [
            [
                {startType: common:SEQUENCE, flowStyle: true},
                {value: "value"},
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: "value"},
                {endType: common:MAPPING},
                {endType: common:SEQUENCE}
            ],
            ["[value, {key: value}]"]
        ],
        "flow mapping nested under flow mapping": [
            [
                {startType: common:MAPPING, flowStyle: true},
                {value: "parentKey"},
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: "value"},
                {endType: common:MAPPING},
                {endType: common:MAPPING}
            ],
            ["{parentKey: {key: value}}"]
        ],
        "empty key and value block mapping": [
            [
                {startType: common:MAPPING},
                {value: ()},
                {value: ()},
                {endType: common:MAPPING}
            ],
            [": "]
        ],
        "empty key and value flow mapping": [
            [
                {startType: common:MAPPING, flowStyle: true},
                {value: ()},
                {value: ()},
                {endType: common:MAPPING}
            ],
            ["{: }"]
        ],
        "empty key block mapping": [
            [
                {startType: common:MAPPING},
                {value: ()},
                {value: "value"},
                {endType: common:MAPPING}
            ],
            [": value"]
        ],
        "empty key flow mapping": [
            [
                {startType: common:MAPPING, flowStyle: true},
                {value: ()},
                {value: "value"},
                {endType: common:MAPPING}
            ],
            ["{: value}"]
        ],
        "empty value block mapping": [
            [
                {startType: common:MAPPING},
                {value: "key"},
                {value: ()},
                {endType: common:MAPPING}
            ],
            ["key: "]
        ],
        "empty value flow mapping": [
            [
                {startType: common:MAPPING, flowStyle: true},
                {value: "key"},
                {value: ()},
                {endType: common:MAPPING}
            ],
            ["{key: }"]
        ],
        "block mapping empty combination": [
            [
                {startType: common:MAPPING},
                {value: ()},
                {value: ()},
                {value: "key"},
                {value: ()},
                {value: ()},
                {value: "value"},
                {endType: common:MAPPING}
            ],
            [": ", "key: ", ": value"]
        ],
        "flow mapping empty combination": [
            [
                {startType: common:MAPPING, flowStyle: true},
                {value: ()},
                {value: ()},
                {value: "key"},
                {value: ()},
                {value: ()},
                {value: "value"},
                {endType: common:MAPPING}
            ],
            ["{: , key: , : value}"]
        ],
        "block sequence with null": [
            [
                {startType: common:SEQUENCE},
                {value: ()},
                {endType: common:SEQUENCE}
            ],
            ["- "]
        ],
        "write only custom tags": [
            [
                {startType: common:SEQUENCE},
                {value: "custom value", tag: "!custom"},
                {value: "string value", tag: yamlStr},
                {endType: common:SEQUENCE}
            ],
            ["- !custom custom value", "- string value"]
        ],
        "single value": [[{value: "value"}], ["value"]]
    };
}

@test:Config {
    groups: ["emitter"]
}
function testMultipleRootEventsForOneDocument() returns error? {
    string[]|EmittingError output = getEmittedOutput([{value: "first root"}, {value: "second root"}]);
    test:assertTrue(output is EmittingError);
}

@test:Config {
    dataProvider: canonicalDataGen,
    groups: ["emitter"]
}
function testWritingInCanonical(common:Event[] events, string[] expectedOutput) returns error? {
    string[] output = check getEmittedOutput(events, canonical = true);
    test:assertEquals(output, expectedOutput);
}

function canonicalDataGen() returns map<[common:Event[], string[]]> {
    return {
        "flow sequence": [
            [
                {startType: common:SEQUENCE, tag: "!custom", flowStyle: true},
                {value: "a", tag: yamlStr},
                {value: "1", tag: yamlInt},
                {endType: common:SEQUENCE}
            ],
            ["!custom [!!str a, !!int 1]"]
        ],
        "empty flow sequence": [
            [
                {startType: common:SEQUENCE, flowStyle: true, tag: yamlSeq},
                {endType: common:SEQUENCE}
            ],
            ["!!seq []"]
        ],
        "empty flow mapping": [
            [
                {startType: common:MAPPING, flowStyle: true, tag: yamlMap},
                {endType: common:MAPPING}
            ],
            ["!!map {}"]
        ],
        "flow mapping": [
            [
                {startType: common:MAPPING, tag: "!custom", flowStyle: true},
                {value: "a", tag: yamlStr},
                {value: "1", tag: yamlInt},
                {endType: common:MAPPING}
            ],
            ["!custom {!!str a: !!int 1}"]
        ],
        "block sequence": [
            [
                {startType: common:SEQUENCE},
                {startType: common:SEQUENCE, tag: "!custom"},
                {value: "a", tag: yamlStr},
                {value: "1", tag: yamlInt},
                {endType: common:SEQUENCE},
                {endType: common:SEQUENCE}
            ],
            ["- !custom", "  - !!str a", "  - !!int 1"]
        ],
        "empty block sequence": [
            [
                {startType: common:SEQUENCE, tag: "!custom"},
                {endType: common:SEQUENCE}
            ],
            ["- !custom"]
        ],
        "block sequence with null": [
            [
                {startType: common:SEQUENCE, tag: yamlSeq},
                {value: (), tag: yamlNull},
                {endType: common:SEQUENCE}
            ],
            ["- !!null "]
        ],
        "block mapping": [
            [
                {startType: common:MAPPING},
                {value: "a", tag: yamlStr},
                {startType: common:MAPPING, tag: "!custom"},
                {value: "b", tag: yamlStr},
                {value: "1", tag: yamlInt},
                {endType: common:MAPPING},
                {endType: common:MAPPING}
            ],
            ["!!str a: !custom", "  !!str b: !!int 1"]
        ],
        "global tag scalar": [[{value: "1", tag: yamlInt}], ["!!int 1"]],
        "local tag scalar": [[{value: "1", tag: "!digit"}], ["!digit 1"]],
        "verbatim tag scalar": [[{value: "1", tag: "verbatim-tag"}], ["!<verbatim-tag> 1"]],
        "no tag scalar": [[{value: "1"}], ["1"]]
    };
}

@test:Config {
    groups: ["emitter"]
}
function testWriteStream() returns error? {
    string[] output = check getEmittedOutput([{value: "1", tag: yamlInt}, {value: "2", tag: yamlInt}], isStream = true);
    test:assertEquals(output, ["---", "1", "---", "2"]);
}

@test:Config {
    dataProvider: invalidEventTreeDataGen
}
function test(common:Event[] inputEventTree) returns error? {
    string[]|EmittingError output = getEmittedOutput(inputEventTree);
    test:assertTrue(output is EmittingError);
}

function invalidEventTreeDataGen() returns map<[common:Event[]]> {
    return {
        "ending a flow style sequence with }": [[{startType: common:SEQUENCE, flowStyle: true}, {endType: common:MAPPING}]],
        "not ending a flow style sequence": [[{startType: common:SEQUENCE, flowStyle: true}]],
        "ending a block style sequence with }": [[{startType: common:SEQUENCE}, {endType: common:MAPPING}]],
        "ending a flow style mapping with ]": [[{startType: common:MAPPING, flowStyle: true}, {endType: common:SEQUENCE}]],
        "not ending a flow style mapping": [[{startType: common:MAPPING, flowStyle: true}]],
        "ending a block style mapping with ]": [[{startType: common:MAPPING}, {endType: common:SEQUENCE}]]
    };
}

@test:Config {
    dataProvider: customTagHandleDataGen,
    groups: ["emitter"]
}
function testReduceCustomTagHandle(common:Event[] inputEventTree, string[] expectedOutput,
    boolean isStream) returns error? {
    string[] output = check getEmittedOutput(inputEventTree,
        customTagHandles = {"!custom!": "org.custom.schema:", "!named!": "org.yaml.named:"}, isStream = isStream);
    test:assertEquals(output, expectedOutput);
}

function customTagHandleDataGen() returns map<[common:Event[], string[], boolean]> {
    final string customTagDirective = "%TAG !custom! org.custom.schema:";
    final string namedTagDirective = "%TAG !named! org.yaml.named:";
    final string customNode = "!custom!scalar value";
    final string namedNode = "!named!string object";
    final common:Event customTagEvent = {value: "value", tag: "org.custom.schema:scalar"};
    final common:Event namedTagEvent = {value: "object", tag: "org.yaml.named:string"};

    return {
        "single document": [
            [customTagEvent],
            [customTagDirective, "---", customNode, "..."],
            false
        ],
        "tags in all document": [
            [customTagEvent, namedTagEvent],
            [customTagDirective, "---", customNode, "...", namedTagDirective, "---", namedNode, "..."],
            true
        ],
        "exclude in some docs": [
            [
                {startType: common:SEQUENCE},
                customTagEvent,
                namedTagEvent,
                {endType: common:SEQUENCE},
                customTagEvent,
                {value: ()},
                {value: ()},
                namedTagEvent
            ],
            [
                customTagDirective,
                namedTagDirective,
                "---",
                "- " + customNode,
                "- " + namedNode,
                "...",
                customTagDirective,
                "---",
                customNode,
                "...",
                "---",
                "",
                "---",
                "",
                "...",
                namedTagDirective,
                "---",
                namedNode,
                "..."
            ],
            true
        ]
    };
}

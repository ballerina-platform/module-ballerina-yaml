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

@test:Config {
    dataProvider: blockScalarEventDataGen,
    groups: ["parser"]
}
function testBlockScalarEvent(string[] lines, string value) returns error? {
    check assertParsingEvent(lines, value);
}

function blockScalarEventDataGen() returns map<[string[], string]> {
    return {
        "correct indentation for indentation-indicator": [["|2", "  value"], " value\n"],
        "capture indented comment": [["|-", " # comment", "# trailing comment"], "# comment"],
        "trailing-lines strip": [["|-", " value", "", " "], "value"],
        "trailing-lines clip": [["|", " value", "", " "], "value\n"],
        "trailing-lines keep": [["|+", " value", "", " "], "value\n\n\n"],
        "empty strip": [["|-", ""], ""],
        "empty clip": [["|", ""], ""],
        "empty keep": [["|+", ""], "\n"],
        "line-break strip": [["|-", " text"], "text"],
        "line-break clip": [["|", " text"], "text\n"],
        "line-break keep": [["|+", " text"], "text\n"],
        "folded lines": [[">-", " first", " second"], "first second"],
        "spaced lines": [[">-", " first", "   second"], "first\n  second"],
        "different lines": [[">-", " first", " second", "", "  first", " second"], "first second\n\n first\nsecond"],
        "same lines": [[">-", " first", " second", "", " first", " second"], "first second\nfirst second"],
        "indent imposed by first line": [[">-", "  first", "  second"], "first second"],
        "ignore trailing comment": [
            [
                "|-",
                " value",
                "# trailing comment",
                " #  trailing comment",
                "",
                " ",
                "   ",
                "    # trailing comment"
            ],
            "value"
        ]
    };
}

@test:Config {
    dataProvider: blockScalarInCollection,
    groups: ["parser"]
}
function testBlockScalarsInCollection(string[] lines, common:Event[] eventTree) returns error? {
    ParserState state = check new (lines);

    foreach common:Event item in eventTree {
        common:Event event = check parse(state);
        test:assertEquals(event, item);
    }
}

function blockScalarInCollection() returns map<[string[], common:Event[]]> {
    return {
        "mapping value after literal": [
            ["key1: >-", " first", " second", "key2: third"],
            [{startType: common:MAPPING}, {value: "key1"}, {value: "first second"}, {value: "key2"}, {value: "third"}]
        ],
        "json mapping value after literal": [
            ["key1: >-", " first", " second", "'key2': third"],
            [
                {startType: common:MAPPING},
                {value: "key1"},
                {value: "first second"},
                {value: "key2", tag: string `${schema:defaultGlobalTagHandle}str`},
                {value: "third"}
            ]
        ],
        "sequence entry after literal": [
            ["- >-", " first", " second", "- third"],
            [{startType: common:SEQUENCE}, {value: "first second"}, {value: "third"}]
        ],
        "sequence entry after trailing comment": [
            ["- >-", " first", "# trailing comment", "- third"],
            [{startType: common:SEQUENCE}, {value: "first"}, {value: "third"}]
        ]
    };
}

@test:Config {
    dataProvider: invalidScalarEventDataGen,
    groups: ["parser"]
}
function testInvalidScalarEvent(string[] lines) returns error? {
    check assertParsingError(lines, true);
}

function invalidScalarEventDataGen() returns map<[string[]]> {
    return {
        "invalid character for double-quoted scalar": [["\"invalid\ncharacter\""]],
        "invalid character for single-quoted scalar": [["'invalid\ncharacter'"]],
        "invalid character for planar scalar": [["invalidcharacter"]],
        "invalid indentation for indentation-indicator": [["|3", " value"]],
        "leading lines contain less space": [["|", "  value", " value"]],
        "value after trailing comment": [["|+", " value", "# first comment", "value"]],
        "value after trailing comment with indent": [["|+", " value", "# first comment", " value"]]
    };
}

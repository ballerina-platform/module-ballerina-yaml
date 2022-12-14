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

@test:Config {
    groups: ["directives", "parser"]
}
function testAccurateYAMLDirective() returns error? {
    ParserState state = check new (["%YAML 1.3 #comment", "---"]);
    _ = check parse(state, docType = ANY_DOCUMENT);
    test:assertEquals(state.yamlVersion, 1.3);
}

@test:Config {
    groups: ["parser"]
}
function testYAMLVersionsOfMultipleDocuments() returns error? {
    ParserState state = check new (["%YAML 1.3", "---", "...", "%YAML 1.1", "---"]);
    _ = check parse(state, docType = DIRECTIVE_DOCUMENT);
    test:assertEquals(state.yamlVersion, 1.3);
    _ = check parse(state, docType = BARE_DOCUMENT);
    _ = check parse(state, docType = DIRECTIVE_DOCUMENT);
    test:assertEquals(state.yamlVersion, 1.1);
}

@test:Config {
    dataProvider: invalidYAMLVersionDataGen,
    groups: ["parser"]
}
function testOnlySupportMajorVersionOne(string line) returns error? {
    check assertParsingError([line]);
}

function invalidYAMLVersionDataGen() returns map<[string]> {
    return {
        "lower version": ["%YAML 0.9"],
        "higher version": ["%YAML 2.1"]
    };
}

@test:Config {
    groups: ["directives", "parser"]
}
function testOnlySupportVersion1() returns error? {
    check assertParsingError(["%YAML 1.3", "%YAML 1.1"]);
}

@test:Config {
    groups: ["directives", "parser"]
}
function testDuplicateYAMLDirectives() returns error? {
    check assertParsingError(["%YAML 1.3", "%YAML 1.1"]);
}

@test:Config {
    dataProvider: invalidDirectiveDataGen,
    groups: ["directives", "parser"]
}
function testInvalidYAMLDirectives(string line) returns error? {
    check assertParsingError(line);
}

function invalidDirectiveDataGen() returns map<[string]> {
    return {
        "additional dot": ["%YAML 1.2.1"],
        "no space": ["%YAML1.2"],
        "single digit": ["%YAML 1"],
        "string for version": ["%YAML one.two"]
    };
}

@test:Config {
    dataProvider: tagHandlesDataGen,
    groups: ["parser"]
}
function testTagHandles(string line, string tagHandle, string tagPrefix) returns error? {
    ParserState state = check new ([line, "---"]);
    _ = check parse(state, docType = ANY_DOCUMENT);
    test:assertEquals(state.customTagHandles[tagHandle], tagPrefix);
}

function tagHandlesDataGen() returns map<[string, string, string]> {
    return {
        "primary": ["%TAG ! local ", "!", "local"],
        "secondary": ["%TAG !! tag:global ", "!!", "tag:global"],
        "named": ["%TAG !a! tag:named ", "!a!", "tag:named"]
    };
}

@test:Config {
    dataProvider: invalidTagDirectiveDataGen,
    groups: ["parser"]
}
function testInvalidTagDirective(string[] inputLines) returns error? {
    check assertParsingError(inputLines);
}

function invalidTagDirectiveDataGen() returns map<[string[]]> {
    return {
        "duplicate of tags": [["%TAG !a! firstPrefix ", "%TAG !a! secondPrefix "]],
        "invalid content": [["%TAG ! local", "anything that is not %"]],
        "invalid tag handle": [["%TAG invalid local"]],
        "primary tag at eol": [["%TAG !"]],
        "invalid starting char for tag prefix": [["%TAG ! [invalid"]],
        "no tag handle": [["%TAG "]],
        "no tag prefix": [["%TAG !a!"]]
    };
}

@test:Config {
    groups: ["parser"]
}
function testInvalidDirectiveInBareDocument() returns error? {
    ParserState state = check new (["---", "%TAG ! local"]);

    _ = check parse(state, docType = ANY_DOCUMENT);
    error|common:Event err = parse(state);

    test:assertTrue(err is ParsingError);
}

@test:Config {
    groups: ["parser"]
}
function testStartingEmptyLines() returns error? {
    check assertParsingEvent(["", " ", "", " value"], "value");
}

@test:Config {
    dataProvider: reservedDirectiveDataGen,
    groups: ["parser"]
}
function testValidReservedDirective(string line, string reservedDirective) returns error? {
    ParserState state = check new ([line, "---"]);
    _ = check parse(state, docType = DIRECTIVE_DOCUMENT);
    test:assertEquals(state.reservedDirectives.pop(), reservedDirective);
}

function reservedDirectiveDataGen() returns map<[string, string]> {
    return {
        "only directive name": ["%RESERVED ", "RESERVED"],
        "one directive parameter": ["%RESERVED parameter ", "RESERVED parameter"],
        "two directive parameters": ["%RESERVED first second", "RESERVED first second"]
    };
}

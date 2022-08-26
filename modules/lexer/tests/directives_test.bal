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

@test:Config {
    dataProvider: directiveDataGen,
    groups: ["directives", "lexer"]
}
function testDirectivesToken(string lexeme, string value) returns error? {
    LexerState state = setLexerString(lexeme);
    check assertToken(state, DIRECTIVE, lexeme = value);
}

function directiveDataGen() returns map<[string, string]> {
    return {
        "yaml-directive": ["%YAML", "YAML"],
        "tag-directive": ["%TAG", "TAG"],
        "reserved-directive": ["%RESERVED", "RESERVED"]
    };
}

@test:Config {
    dataProvider: invalidUriHexDataGen,
    groups: ["lexer"]
}
function testInvalidURIHexCharacters(string lexeme) returns error? {
    assertLexicalError(lexeme, context = LEXER_TAG_PREFIX);
}

function invalidUriHexDataGen() returns map<[string]> {
    return {
        "one digit": ["%a"],
        "no digit": ["%"],
        "two %": ["%1%"]
    };
}

@test:Config {
    dataProvider: validTagDataGen,
    groups: ["lexer"]
}
function testValidTagHandlers(string tag, string lexeme) returns error? {
    LexerState state = setLexerString(tag, LEXER_TAG_HANDLE);
    check assertToken(state, TAG_HANDLE, lexeme = lexeme);
}

function validTagDataGen() returns map<[string, string]> {
    return {
        "primary": ["! ", "!"],
        "secondary": ["!! ", "!!"],
        "named": ["!named! ", "!named!"]
    };
}

@test:Config {
    dataProvider: tagPrefixDataGen,
    groups: ["lexer"]
}
function testTagPrefixTokens(string lexeme, string value) returns error? {
    LexerState state = setLexerString(lexeme, LEXER_TAG_PREFIX);
    check assertToken(state, TAG_PREFIX, lexeme = value);
}

function tagPrefixDataGen() returns map<[string, string]> {
    return {
        "local-tag-prefix": ["!local- ", "!local-"],
        "global-tag-prefix": ["tag:example.com,2000:app/  ", "tag:example.com,2000:app/"],
        "global-tag-prefix starting hex": ["%21global  ", "!global"],
        "global-tag-prefix inline hex": ["global%21hex  ", "global!hex"],
        "global-tag-prefix single-hex": ["%21  ", "!"]
    };
}

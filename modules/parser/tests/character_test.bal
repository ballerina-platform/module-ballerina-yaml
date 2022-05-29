import ballerina/test;
import yaml.common;
import yaml.schema;

@test:Config {
    dataProvider: lineFoldingDataGen,
    groups: ["parser"]
}
function testProcessLineFolding(string[] arr, string value) returns error? {
    check assertParsingEvent(arr, value);
}

function lineFoldingDataGen() returns map<[string[], string]> {
    return {
        "space": [["\"as", "space\""], "as space"],
        "space-empty": [["\"", "space\""], " space"]
    };
}

@test:Config {
    dataProvider: invalidNodeTagDataGen,
    groups: ["parser"]
}
function testInvalidNodeTagToken(string line, boolean isLexical) returns error? {
    check assertParsingError(line, isLexical, customTagHandles = {"!e!": "tag:named:"});
}

function invalidNodeTagDataGen() returns map<[string, boolean]> {
    return {
        "verbatim primary": ["!<!>", true],
        "verbatim empty": ["!<>", true],
        "tag-shorthand no-suffix": ["!e!", false]
    };
}

@test:Config {
    dataProvider: tagShorthandDataGen,
    groups: ["parser"]
}
function testTagShorthandEvent(string line, string tag) returns error? {
    check assertParsingEvent(line, tag = tag, customTagHandles = {"!e!": "tag:named:"});
}

function tagShorthandDataGen() returns map<[string, string]> {
    return {
        "primary": ["!local value", "!local"],
        "secondary": ["!!str value", string `${schema:defaultGlobalTagHandle}str`],
        "named": ["!e!tag value", "tag:named:tag"],
        "escaped": ["!e!tag%21 value", "tag:named:tag!"],
        "double!": ["!%21 value", "!!"]
    };
}

@test:Config {
    dataProvider: invalidTagShorthandDataGen,
    groups: ["parser"]
}
function testInvalidTagShorthandEvent(string line, boolean isLexical) returns error? {
    check assertParsingError(line, isLexical, customTagHandles = {"!e!": "tag:named:"});
}

function invalidTagShorthandDataGen() returns map<[string, boolean]> {
    return {
        "no suffix": ["!e! value", false],
        "terminating !": ["!e!tag! value", true]
    };
}

@test:Config {
    dataProvider: nodeSeparateDataGen,
    groups: ["parser"]
}
function testNodeSeparationEvent(string[] arr, string tag) returns error? {
    check assertParsingEvent(arr, "value", tag, "anchor");
}

function nodeSeparateDataGen() returns map<[string[], string]> {
    return {
        "single space": [["!tag &anchor value"], "!tag"],
        "verbatim tag": [["!<tag> &anchor value"], "tag"],
        "new line": [["!!tag", "&anchor value"], "tag:yaml.org,2002:tag"],
        "with comment": [["!tag #first-comment", "#second-comment", "&anchor value"], "!tag"],
        "anchor first": [["&anchor !tag value"], "!tag"]
    };
}

@test:Config {
    groups: ["parser"]
}
function testAliasEvent() returns error? {
    ParserState state = check new (["*anchor"]);
    common:Event event = check parse(state);

    test:assertEquals((<common:AliasEvent>event).alias, "anchor");
}

@test:Config {
    dataProvider: endEventDataGen,
    groups: ["parser"]
}
function testEndEvent(string line, common:Collection endType) returns error? {
    ParserState state = check new ([line]);
    common:Event event = check parse(state);

    test:assertEquals((<common:EndEvent>event).endType, endType);
}

function endEventDataGen() returns map<[string, common:Collection]> {
    return {
        "end-sequence": ["]", common:SEQUENCE],
        "end-mapping": ["}", common:MAPPING],
        "end-stream": ["", common:STREAM]
    };
}

@test:Config {
    dataProvider: startEventDataGen,
    groups: ["parser"]
}
function testStartEvent(string line, common:Collection eventType, string? anchor) returns error? {
    ParserState state = check new ([line]);
    common:Event event = check parse(state);

    test:assertEquals((<common:StartEvent>event).startType, eventType);
    test:assertEquals((<common:StartEvent>event).anchor, anchor);
}

function startEventDataGen() returns map<[string, common:Collection, string?]> {
    return {
        "mapping-start with tag": ["&anchor {", common:MAPPING, "anchor"],
        "mapping-start": ["{", common:MAPPING, ()],
        "sequence-start with tag": ["&anchor [", common:SEQUENCE, "anchor"],
        "sequence-start": ["[", common:SEQUENCE, ()]
    };
}

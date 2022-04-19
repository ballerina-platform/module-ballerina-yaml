import ballerina/test;
import yaml.event;

@test:Config {
    dataProvider: blockScalarEventDataGen
}
function testBlockScalarEvent(string[] lines, string value) returns error? {
    check assertParsingEvent(lines, value);
}

function blockScalarEventDataGen() returns map<[string[], string]> {
    return {
        "correct indentation for indentation-indicator": [["|2", "  value"], "value\n"],
        "ignore trailing comment": [["|-", " value", "# trailing comment", " #  trailing comment"], "value"],
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
        "indent imposed by first line": [[">-", "  first", "  second"], "first second"]
    };
}

@test:Config {
    dataProvider: blockScalarInCollection
}
function testBlockScalarsInCollection(string[] lines, event:Event[] eventTree) returns error? {
    ParserState state = check new (lines);

    foreach event:Event item in eventTree {
        event:Event event = check parse(state);
        test:assertEquals(event, item);
    }
}

function blockScalarInCollection() returns map<[string[], event:Event[]]> {
    return {
        "folded scalar as mapping value": [["key1: >-", " first", " second", "key2: third"], [{startType: event:MAPPING}, {value: "key1"}, {value: "first second"}, {value: "key2"}, {value: "third"}]],
        "folded scalar as sequence entry": [["- >-", " first", " second", "- third"], [{startType: event:SEQUENCE}, {value: "first second"}, {value: "third"}]],
        "folded scalar after trailing comment": [["- >-", " first", "# trailing comment", "- third"], [{startType: event:SEQUENCE}, {value: "first"}, {value: "third"}]]
    };
}

@test:Config {
    dataProvider: invalidBlockScalarEventDataGen
}
function testInvalidBlockScalarEvent(string[] lines) returns error? {
    check assertParsingError(lines, true);
}

function invalidBlockScalarEventDataGen() returns map<[string[]]> {
    return {
        "invalid indentation for indentation-indicator": [["|2", " value"]],
        "leading lines contain less space": [["|2", "  value", " value"]],
        "value after trailing comment": [["|+", " value", "# first comment", "value"]]
    };
}

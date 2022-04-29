import ballerina/test;
import yaml.schema;

@test:Config {
    dataProvider: jsonLineDataGen
}
function testJSONSchema(string line, json expectedOutput) returns error? {
    ComposerState state = check new ([line], schema:getJsonSchemaTags());
    json output = check composeDocument(state);
    test:assertEquals(output, expectedOutput);
}

function jsonLineDataGen() returns map<[string, json]> {
    return {
        "boolean true": ["true", true],
        "boolean false": ["false", false],
        "zero int": ["0", 0],
        "positive int": ["1", 1],
        "negative int": ["-1", -1],
        "plus prefix value is string": ["+1", "+1"],
        "leading zero value is string": ["01", "01"],
        "decimal point float": ["1.1", 1.1],
        "decimal point negative exponential float": ["1.1E-10", 1.1E-10],
        "decimal point positive exponential float": ["1.1E10", 1.1E10],
        "null": ["null", ()],
        "must change the type to the explicit tag": ["!!int 123", 123]
    };
}

@test:Config {
    dataProvider: coreLineDataGen
}
function testCORESchema(string line, json expectedOutput) returns error? {
    ComposerState state = check new ([line], schema:getCoreSchemaTags());
    json output = check composeDocument(state);
    test:assertEquals(output, expectedOutput);
}

function coreLineDataGen() returns map<[string, json]> {
    return {
        "valid octal": ["0o71", 57],
        "invalid octal": ["0o81", "0o81"],
        "invalid negative octal": ["-0o71", "-0o71"],
        "valid hexadecimal": ["0xa1", 161],
        "invalid hexadecimal": ["0xg1", "0xg1"],
        "invalid negative hexadecimal": ["-0xa1", "-0xa1"],
        "positive infinity": [".inf", 'float:Infinity],
        "negative infinity": ["-.inf", -'float:Infinity],
        "not a number": [".nan", 'float:NaN]
    };
}


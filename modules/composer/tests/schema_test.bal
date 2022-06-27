import ballerina/test;
import yaml.schema;

type RGB [int, int, int];

function constructRGB(json data) returns json|schema:SchemaError {
    RGB|error value = data.cloneWithType();

    if value is error {
        return error("Invalid shape for RGB");
    }

    foreach int index in value {
        if index > 255 || index < 0 {
            return error("One RGB value must be between 0-255");
        }
    }

    return value;
}

@test:Config {
    dataProvider: jsonLineDataGen,
    groups: ["composer"]
}
function testJSONSchema(string line, json expectedOutput) returns error? {
    ComposerState state = check obtainComposerState([line], tagSchema = schema:getJsonSchemaTags());
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
        "decimal point float": ["1.1", <decimal>1.1],
        "decimal point negative exponential float": ["1.1E-10", <decimal>1.1E-10],
        "decimal point positive exponential float": ["1.1E10", <decimal>1.1E10],
        "null": ["null", ()],
        "must change the type to the explicit tag": ["!!int 123", 123]
    };
}

@test:Config {
    dataProvider: coreLineDataGen,
    groups: ["composer"]
}
function testCORESchema(string line, json expectedOutput) returns error? {
    ComposerState state = check obtainComposerState([line], tagSchema = schema:getCoreSchemaTags());
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
        "positive infinity": [".inf", float:Infinity],
        "negative infinity": ["-.inf", -float:Infinity],
        "not a number": [".nan", float:NaN]
    };
}

@test:Config {
    groups: ["composer"]
}
function testCustomTag() returns error? {
    map<schema:YAMLTypeConstructor> tagSchema = schema:getJsonSchemaTags();
    tagSchema["!rgb"] = {
        kind: schema:SEQUENCE,
        construct: constructRGB,
        identity: function(json data) returns boolean {
            RGB|error output = data.cloneWithType();
            return output is RGB;
        },
        represent: function(json data) returns string => data.toString()
    };

    ComposerState state = check obtainComposerState(["!rgb [123, 12, 32]"], tagSchema = tagSchema);
    json output = check composeDocument(state);
    RGB expectedOutput = [123, 12, 32];

    test:assertEquals(output, expectedOutput);
}

@test:Config {
    groups: ["composer"]
}
function testInvalidCustomTag() returns error? {
    map<schema:YAMLTypeConstructor> tagSchema = schema:getJsonSchemaTags();
    tagSchema["!rgb"] = {
        kind: schema:SEQUENCE,
        construct: constructRGB,
        identity: schema:generateIdentityFunction(RGB),
        represent: function(json data) returns string => data.toString()
    };

    
    ComposerState state = check obtainComposerState(["!rgb [256, 12, 32]"], tagSchema = tagSchema);
    json|error output = composeDocument(state);

    test:assertTrue(output is schema:SchemaError);
}

import ballerina/file;
import ballerina/io;
import ballerina/test;

@test:Config {
    groups: ["api"]
}
function testReadTOMLString() returns error? {
    json output = check readString(string `
        outer:
          inner: {outer: inner}
        seq:
          - - [[nested, sequence]]
        int: 1
        bool: true
        float: 1.1`);

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
    groups: ["api"]
}
function testReadYAMLSchema(YAMLSchema schema, json expectedOutput) returns error? {
    json output = check readString(string `
        int: 1
        bool: true
        nan: .nan`, schema = schema);

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

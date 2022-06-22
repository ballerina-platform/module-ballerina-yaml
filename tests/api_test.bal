import ballerina/file;
import ballerina/io;
import ballerina/test;

@test:Config {
    groups: ["api"]
}
function testReadTOMLString() returns error? {
    json output = check readString(string
        `outer:
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
        "float": 1.1
    });
}

@test:Config {
    groups: ["api"]
}
function testReadTOMLFile() returns error? {
    check io:fileWriteString("input.toml", "bool: true\nint: 1");
    json output = check readFile("input.toml");
    test:assertEquals(output, {"bool": true, "int": 1});
    check file:remove("input.toml");
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

@test:Config {}
function testInvalidAttemptWriteToDirectory() returns error? {
    check file:createDir("output");
    FileError? err = openFile("output");
    test:assertTrue(err is FileError);
    check file:remove("output");
}

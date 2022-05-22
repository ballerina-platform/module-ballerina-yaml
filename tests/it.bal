import ballerina/test;

@test:Config {
    dataProvider: yamlDataGen
}
function testYAMLIntegrationTest(string filePath, json expectedOutput, boolean isStream, boolean isError) returns error? {
    YAMLType primaryFooType = {
        tag: "!foo",
        ballerinaType: string,
        kind: STRING,
        construct: function(json data) returns json => data,
        represent: function(json data) returns string => data.toString()
    };
    YAMLType globalFooType = {
        tag: "tag:example.com,2000:app/foo",
        ballerinaType: string,
        kind: STRING,
        construct: function(json data) returns json => data,
        represent: function(json data) returns string => data.toString()
    };

    json|Error output = read(filePath, {yamlTypes: [primaryFooType, globalFooType]}, isStream = isStream);
    if isError {
        test:assertTrue(output is Error);
    } else {
        test:assertEquals(output, expectedOutput);
    }
}

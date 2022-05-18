import ballerina/test;

@test:Config {
    dataProvider: yamlDataGen
}
function testYAMLIntegrationTest(string filePath, json? expectedOutput, boolean isStream) returns error? {
    json|Error output = read(filePath, isStream = isStream);
    if expectedOutput == () {
        test:assertTrue(output is Error);
    } else {
        test:assertEquals(output, expectedOutput);
    }
}

import ballerina/test;
import yaml.schema;

@test:Config {
    dataProvider: jsonLineDataGen
}
function testJSONSchema(string line, json expectedOutput) returns error? {
    ComposerState state = check new ([line], schema:getJSONSchemaTags());
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

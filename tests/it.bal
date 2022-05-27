import ballerina/test;

YAMLType[] customYamlTypes = [];
map<FailSafeSchema> customTags = {
    "!": STRING,
    "!foo": STRING,
    "tag:example.com,2000:app/foo": STRING,
    "tag:yaml.org,2002:set": MAPPING,
    "tag:yaml.org,2002:binary": STRING,
    "!my-light": STRING,
    "!local": STRING,
    "!bar": STRING,
    "tag:clarkevans.com,2002:circle": MAPPING,
    "tag:clarkevans.com,2002:line": MAPPING,
    "tag:clarkevans.com,2002:label": MAPPING,
    "tag:yaml.org,2002:omap": SEQUENCE,
    "tag:example.com,2000:app/int": STRING,
    "tag:example.com,2000:app/tag!": STRING,
    "tag:example.com,2011:A": STRING
};

@test:BeforeSuite
function initYamlCustomeTypes() {
    customTags.entries().forEach(function([string, FailSafeSchema] entry) {
        customYamlTypes.push({
            tag: entry[0],
            ballerinaType: string,
            kind: entry[1],
            construct: function(json data) returns json => data,
            represent: function(json data) returns string => data.toString()
        });
    });
}

@test:Config {
    dataProvider: yamlDataGen
}
function testYAMLIntegrationTest(string filePath, json expectedOutput, boolean isStream, boolean isError) returns error? {
    json|Error output = read(filePath, {yamlTypes: customYamlTypes}, isStream = isStream);
    if isError {
        test:assertTrue(output is Error);
    } else {
        test:assertEquals(output, expectedOutput);
    }
}

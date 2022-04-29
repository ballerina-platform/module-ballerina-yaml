import yaml.schema;
import ballerina/file;

# Checks if the file exists. If not, creates a new file.
#
# + fileName - Path to the file
# + return - An error on failure
function openFile(string fileName) returns error? {
    // Check if the given fileName is not directory
    if (check file:test(fileName, file:IS_DIR)) {
        return error("Cannot write to a directory");
    }

    // Create the file if the file does not exists
    if (!check file:test(fileName, file:EXISTS)) {
        check file:create(fileName);
    }
}

function generateTagHandlesMap(YAMLType[] yamlTypes, YAMLSchema yamlSchema) returns map<schema:YAMLTypeConstructor> {
    map<schema:YAMLTypeConstructor> tagHandles = {};

    // Obtain the default tag handles.
    match yamlSchema {
        JSON_SCHEMA => {
            tagHandles = schema:getJsonSchemaTags();
        }
        CORE_SCHEMA => {
            tagHandles = schema:getCoreSchemaTags();
        }
    }

    // Add the custom tags to the tag handles.
    yamlTypes.forEach(function(YAMLType yamlType) {
        tagHandles[yamlType.tag] = {
            kind: yamlType.kind,
            construct: yamlType.construct,
            identity: schema:generateIdentityFunction(yamlType.ballerinaType),
            represent: yamlType.represent
        };
    });

    return tagHandles;
}

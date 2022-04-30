import ballerina/io;
import yaml.emitter;
import yaml.serializer;
import yaml.composer;

# Parses one YAML document to Ballerina data structure.
#
# + filePath - Path to the YAML file
# + config - Configurations for reading a YAML file
# + return - The ballerina data structure o success.
public function readDocument(string filePath, ReadConfig config = {}) returns json|error {
    string[] lines = check io:fileReadLines(filePath);
    composer:ComposerState composerState = check new (lines, generateTagHandlesMap(config.yamlTypes, config.schema));

    return composer:composeDocument(composerState);
}

# Parses a stream of YAML documents to Ballerina array.
#
# + filePath - Path to the YAML file
# + config - Configurations for reading a YAML file
# + return - An array of Ballerina data structures on success.
public function readAll(string filePath, ReadConfig config = {}) returns json[]|error {
    string[] lines = check io:fileReadLines(filePath);
    composer:ComposerState composerState = check new (lines, generateTagHandlesMap(config.yamlTypes, config.schema));

    return composer:composeStream(composerState);
}

# Write a single YAML document into a file.
#
# + fileName - Path to the file  
# + yamlDoc - Document to be written to the file
# + config - Configurations for writing a YAML file
# + return - An error on failure
public function writeDocument(string fileName, json yamlDoc, WriteConfig config = {}) returns error? {
    check openFile(fileName);

    // Obtain the content for the YAML file
    string[] output = check emitter:emit(
        events = check serializer:serialize(
            data = yamlDoc,
            tagSchema = generateTagHandlesMap(config.yamlTypes, config.schema),
            blockLevel = config.blockLevel
        ),
        indentationPolicy = config.indentationPolicy,
        tagSchema = {},
        isStream = false,
        canonical = config.canonical
    );

    check io:fileWriteLines(fileName, output);
}

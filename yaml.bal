import ballerina/io;
import yaml.emitter;
import yaml.serializer;
import yaml.composer;

# Parses YAML document(s) to Ballerina data structures.
#
# + filePath - Path to the YAML file  
# + config - Configurations for reading a YAML file  
# + isStream - If set, the parser reads a stream of YAML documents
# + return - The ballerina data structure on success.
public function read(string filePath, ReadConfig config = {}, boolean isStream = false) returns json|Error {
    string[] lines = check io:fileReadLines(filePath);
    composer:ComposerState composerState = check new (lines, generateTagHandlesMap(config.yamlTypes, config.schema));

    return isStream ? composer:composeStream(composerState) : composer:composeDocument(composerState);
}

# Parses single YAML string line to Ballerina data structures.
#
# + yamlString - Single YAML line string to be parsed
# + config - Configurations for reading a YAML file  
# + return - The ballerina data structure on success.
public function readString(string yamlString, ReadConfig config = {}) returns json|Error {
    composer:ComposerState composerState = check new([yamlString],generateTagHandlesMap(config.yamlTypes, config.schema));
    return composer:composeDocument(composerState);
}

# Write a single YAML document into a file.
#
# + fileName - Path to the file  
# + yamlDoc - Document to be written to the file  
# + config - Configurations for writing a YAML file  
# + isStream - If set, the parser will write a stream of YAML documents
# + return - An error on failure
public function write(string fileName, json yamlDoc, WriteConfig config = {}, boolean isStream = false) returns Error? {
    check openFile(fileName);

    // Obtain the content for the YAML file
    string[] output = check emitter:emit(
        events = check serializer:serialize(
            data = yamlDoc,
            tagSchema = generateTagHandlesMap(config.yamlTypes, config.schema),
            blockLevel = config.blockLevel,
            delimiter = config.useSingleQuotes ? "'" : "\"",
            forceQuotes = config.forceQuotes
        ),
        indentationPolicy = config.indentationPolicy,
        tagSchema = {},
        isStream = isStream,
        canonical = config.canonical
    );

    check io:fileWriteLines(fileName, output);
}

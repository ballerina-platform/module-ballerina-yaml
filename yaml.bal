import ballerina/io;
import yaml.emitter;
import yaml.serializer;
import yaml.composer;

# Parses a Ballerina string of YAML content into a Ballerina map object.
#
# + yamlString - YAML content
# + config - Configuration for reading a YAML file
# + return - YAML map object on success. Else, returns an error
public function readString(string yamlString, *ReadConfig config) returns json|Error {
    composer:ComposerState composerState = check new ([yamlString],
        generateTagHandlesMap(config.yamlTypes, config.schema), config.allowAnchorRedefinition,
        config.allowMapEntryRedefinition);
    return composer:composeDocument(composerState);
}

# Parses a YAML file into a Ballerina json object.
#
# + filePath - Path to the YAML file
# + config - Configuration for reading a YAML file
# + return - YAML map object on success. Else, returns an error
public function readFile(string filePath, *ReadConfig config) returns json|Error {
    string[] lines = check io:fileReadLines(filePath);
    composer:ComposerState composerState = check new (lines, generateTagHandlesMap(config.yamlTypes, config.schema),
        config.allowAnchorRedefinition, config.allowMapEntryRedefinition);
    return config.isStream ? composer:composeStream(composerState) : composer:composeDocument(composerState);
}

# Converts the YAML structure to an array of strings.
#
# + yamlStructure - Structure to be written to the file
# + config - Configurations for writing a YAML file
# + return - YAML content on success. Else, an error on failure
public function writeString(json yamlStructure, *WriteConfig config) returns string[]|Error {
    serializer:SerializerState serializerState = {
        events: [],
        tagSchema: generateTagHandlesMap(config.yamlTypes, config.schema),
        blockLevel: config.blockLevel,
        delimiter: config.useSingleQuotes ? "'" : "\"",
        forceQuotes: config.forceQuotes
    };
    check serializer:serialize(serializerState, yamlStructure);
    return emitter:emit(
        events = serializerState.events,
        customTagHandles = config.customTagHandles,
        indentationPolicy = config.indentationPolicy,
        isStream = config.isStream,
        canonical = config.canonical
    );
}

# Writes the YAML structure to a file.
#
# + filePath - Path to the file  
# + yamlStructure - Structure to be written to the file
# + config - Configurations for writing a YAML file
# + return - An error on failure
public function writeFile(string filePath, json yamlStructure, *WriteConfig config) returns Error? {
    check openFile(filePath);
    string[] output = check writeString(yamlStructure, config);
    check io:fileWriteLines(filePath, output);
}

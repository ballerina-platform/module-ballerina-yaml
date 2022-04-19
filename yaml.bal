import ballerina/io;
import yaml.emitter;
import yaml.serializer;

# Configurations for writing a YAML document.
#
# + indentationPolicy - Number of whitespace for an indentation  
# + blockLevel - The maximum depth level for a block collection.
public type WriteConfig record {|
    int indentationPolicy = 2;
    int blockLevel = 1;
|};

# Write a single YAML document into a file.
#
# + fileName - Path to the file  
# + yamlDoc - Document to be written to the file
# + config - Configurations for writing a YAML file
# + return - An error on failure
public function writeDocument(string fileName, json yamlDoc, WriteConfig config) returns error? {
    check openFile(fileName);
    string[] output = check emitter:emit(
        check serializer:serialize(yamlDoc, config.blockLevel),
        config.indentationPolicy,
        false);
    check io:fileWriteLines(fileName, output);
}


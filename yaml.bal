import yaml.serializer;
import ballerina/io;
import yaml.emitter;

# Configurations for writing a YAML document.
#
# + indentationPolicy - Number of whitespace for an indentation  
# + blockLevel - The maximum depth level for a block collection.
public type WriteConfig record {|
    int indentationPolicy = 2;
    int blockLevel = 1;
|};

public function writeDocument(string fileName, json yamlStructure, WriteConfig config) returns error? {
    check openFile(fileName);
    string[] output = check emitter:emit(
        check serializer:serialize(yamlStructure, config.blockLevel),
        config.indentationPolicy,
        false);
    check io:fileWriteLines(fileName, output);
}


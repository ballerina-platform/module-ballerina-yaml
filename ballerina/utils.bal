// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import yaml.schema;
import yaml.composer;

import ballerina/file;

# Checks if the file exists. If not, creates a new file.
#
# + fileName - Path to the file
# + return - An error on failure
isolated function openFile(string fileName) returns FileError? {
    // Check if the given fileName is not directory
    if check file:test(fileName, file:IS_DIR) {
        return error("Cannot write to a directory");
    }

    // Create the file if the file does not exists
    if !check file:test(fileName, file:EXISTS) {
        check file:create(fileName);
    }
}

# Generates all the tag handles for the conversion request.
#
# + yamlTypes - List of custom YAML types
# + yamlSchema - YAML schema for the current request
# + return - List of all the YAML tags
isolated function generateTagHandlesMap(YamlType[] yamlTypes, YAMLSchema yamlSchema) returns map<schema:YAMLTypeConstructor> {
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
    foreach var yamlType in yamlTypes {
        tagHandles[yamlType.tag] = {
            kind: yamlType.kind,
            construct: yamlType.construct,
            identity: schema:generateIdentityFunction(yamlType.ballerinaType),
            represent: yamlType.represent
        };
    }

    return tagHandles;
}

# Parses the given lines of YAML and returns the JSON representation.
#
# + lines - Lines of the YAML document
# + config - Configuration for the YAML parser
# + return - JSON representation of the YAML document
isolated function readLines(string[] lines, ReadConfig config) returns json|Error {
    composer:ComposerState composerState = check new (lines, generateTagHandlesMap(config.yamlTypes, config.schema),
        config.allowAnchorRedefinition, config.allowMapEntryRedefinition
    );
    return config.isStream ? composer:composeStream(composerState) : composer:composeDocument(composerState);
}

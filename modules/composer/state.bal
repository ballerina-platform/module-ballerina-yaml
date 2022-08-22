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

import yaml.parser;
import yaml.common;
import yaml.schema;

# Represents the state of the Composer
public class ComposerState {
    # Current parser state.
    parser:ParserState parserState;

    # Hash map of the anchor to the respective Ballerina data.
    map<json> anchorBuffer = {};

    # Flag is set if the end of the document is reached.
    common:DocumentMarkerEvent? terminatedDocEvent = ();

    # Custom tag schema for the YAML parser.
    map<schema:YAMLTypeConstructor> tagSchema = {};

    # Flag is set if anchors can be redefined multiple times
    readonly & boolean allowAnchorRedefinition;

    # Flag is set if same map keys are allowed in a mapping
    readonly & boolean allowMapEntryRedefinition;

    public function init(string[] lines, map<schema:YAMLTypeConstructor> tagSchema,
        boolean allowAnchorRedefinition, boolean allowMapEntryRedefinition) returns parser:ParsingError? {

        self.parserState = check new (lines);
        self.tagSchema = tagSchema;
        self.allowAnchorRedefinition = allowAnchorRedefinition;
        self.allowMapEntryRedefinition = allowMapEntryRedefinition;
    }
}

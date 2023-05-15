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

import ballerina/lang.array;
import yaml.common;

# Represents the variables of the Emitter state.
public class EmitterState {
    # YAML content of a document as an array of strings
    string[] document;
    string[] documentTags;

    # Custom tag handles that can be included in the directive document
    map<string> customTagHandles;

    # Total whitespace for a single indent
    readonly & string indent;

    # If set, the tag is written explicitly along with the value
    readonly & boolean canonical;

    private boolean lastBareDoc = false;

    # Event tree to be converted
    common:Event[] events;

    public isolated function init(common:Event[] events, map<string> customTagHandles,
        int indentationPolicy, boolean canonical) {

        self.events = events;
        self.customTagHandles = customTagHandles;
        self.canonical = canonical;
        self.document = [];
        self.documentTags = [];

        // Setup the total whitespace for an indentation
        string indent = "";
        foreach int i in 1 ... indentationPolicy {
            indent += " ";
        }
        self.indent = indent;
    }

    isolated function addLine(string line) => self.document.push(line);

    isolated function addTagHandle(string tagHandle) {
        if self.documentTags.indexOf(tagHandle) == () {
            self.documentTags.push(tagHandle);
        }
    }

    isolated function getDocument(boolean isStream = false) returns string[] {
        string[] output = self.document.clone();

        if self.documentTags.length() > 0 {
            output.unshift("---");
            foreach var tagHandle in self.documentTags.sort(array:DESCENDING) {
                output.unshift(string `%TAG ${tagHandle} ${self.customTagHandles.get(tagHandle)}`);
            }    
            if self.lastBareDoc {
                output.unshift("...");
                self.lastBareDoc = false;
            }
            output.push("...");
        } else if isStream && output.length() > 0 {
            output.unshift("---");
            self.lastBareDoc = true;
        }

        self.document = [];
        self.documentTags = [];

        return output;
    }
}

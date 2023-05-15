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

import yaml.common;

# Obtain the output string lines for a given event tree.
#
# + state - Parameter Description  
# + isStream - Whether the event tree is a stream
# + return - Output YAML content as an array of strings.
public isolated function emit(EmitterState state, boolean isStream) returns string[]|EmittingError {
    if isStream { // Write YAML stream
        string[] output = [];
        while state.events.length() > 0 {
            check write(state);
            foreach var line in state.getDocument(true) {
                output.push(line);
            }
        }
        return output;
    } else { // Write a single YAML document
        check write(state);
        if state.events.length() > 0 {
            return generateEmittingError("There can only be one root event for a document", getEvent(state));
        }
        return state.getDocument();
    }
}

# Convert a single YAML document to array of YAML strings
#
# + state - Current emitter state
# + return - An error on failure
isolated function write(EmitterState state) returns EmittingError? {
    common:Event event = getEvent(state);

    // Convert sequence collection
    if event is common:StartEvent && event.startType == common:SEQUENCE {
        if event.flowStyle {
            state.addLine(check writeFlowSequence(state, event.tag));
        } else {
            check writeBlockSequence(state, "", event.tag);
        }
        return;
    }

    // Convert mapping collection
    if event is common:StartEvent && event.startType == common:MAPPING {
        if event.flowStyle {
            state.addLine(check writeFlowMapping(state, event.tag));
        } else {
            check writeBlockMapping(state, "", event.tag);
        }
        return;
    }

    // Convert scalar 
    if event is common:ScalarEvent {
        state.addLine(writeNode(state, event.value, event.tag));
        return;
    }
}

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

# Convert a flow sequence into YAML string.
#
# + state - Current emitter state
# + tag - Tag of the start event if exists
# + return - YAML string of the flow sequence.
isolated function writeFlowSequence(EmitterState state, string? tag) returns string|EmittingError {
    string line = writeNode(state, "[", tag);
    common:Event event = getEvent(state);
    boolean firstValue = true;

    // Iterate until the end delimiter ']' is detected
    while true {
        if event is common:EndEvent {
            match event.endType {
                common:SEQUENCE => { // End delimiter is detected
                    break;
                }
                _ => { // Any other end events are not accepted
                    return generateExpectedEndEventError(event.endType, common:SEQUENCE);
                }
            }
        }

        if !firstValue {
            line += ", ";
        }

        // Convert the scalar
        if event is common:ScalarEvent {
            line += writeNode(state, event.value, event.tag);
        }

        // Check for nested flow collections. Block collections are not allowed.
        if event is common:StartEvent {
            match event.startType {
                common:SEQUENCE => { // Convert the nested flow sequence
                    line += check writeFlowSequence(state, event.tag);
                }
                common:MAPPING => { // Convert the nested flow mapping
                    line += check writeFlowMapping(state, event.tag);
                }
            }
        }

        event = getEvent(state);
        firstValue = false;
    }

    line += "]";
    return line;
}

# Convert a block sequence into YAML string.
#
# + state - Current emitter state  
# + whitespace - Whitespace at the start of it
# + tag - Tag of the start event if exists
# + return - YAML string of the block sequence.
isolated function writeBlockSequence(EmitterState state, string whitespace, string? tag) returns EmittingError? {
    common:Event event = getEvent(state);
    boolean emptySequence = true;

    // Iterate until and end event is detected
    while true {
        if event is common:EndEvent {
            match event.endType {
                common:SEQUENCE|common:STREAM => { // Terminate for these events
                    if emptySequence {
                        state.addLine(whitespace + writeNode(state, "-", tag, true));
                    }
                    break;
                }
                common:MAPPING => { // End mapping events are not allowed
                    return generateExpectedEndEventError(event.endType, common:SEQUENCE);
                }
            }
        }

        // Convert scalar event
        if event is common:ScalarEvent {
            state.addLine(string `${whitespace}- ${writeNode(state, event.value, event.tag)}`);
        }

        // Check for nested collections
        if event is common:StartEvent {
            match event.startType {
                common:SEQUENCE => { // Convert the nested sequence
                    if event.flowStyle {
                        state.addLine(whitespace + "- " + check writeFlowSequence(state, event.tag));
                    } else {
                        state.addLine(whitespace + writeNode(state, "-", event.tag, true));
                        check writeBlockSequence(state, whitespace + state.indent, event.tag);
                    }
                }
                common:MAPPING => { // Convert the nested mapping
                    if event.flowStyle {
                        state.addLine(whitespace + "- " + check writeFlowMapping(state, event.tag));
                    } else {
                        state.addLine(whitespace + "-");
                        check writeBlockMapping(state, whitespace + state.indent, event.tag);
                    }
                }
            }
        }

        event = getEvent(state);
        emptySequence = false;
    }
}

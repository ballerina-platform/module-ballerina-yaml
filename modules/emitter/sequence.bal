import yaml.event;

# Convert a flow sequence into YAML string.
#
# + state - Current emitter state
# + return - YAML string of the flow sequence.
function writeFlowSequence(EmitterState state) returns string|EmittingError {
    string line = "[";
    event:Event event = getEvent(state);

    // Iterate until the end delimiter ']' is detected
    while true {
        if event is event:EndEvent {
            match event.endType {
                event:SEQUENCE => { // End delimiter is detected
                    break;
                }
                _ => { // Any other end events are not accepted
                    return generateError("Expected the flow mapping to be terminated");
                }
            }
        }

        // Convert the scalar
        if event is event:ScalarEvent {
            line += event.value.toString();
        }

        // Check for nested flow collections. Block collections are not allowed.
        if event is event:StartEvent {
            match event.startType {
                event:SEQUENCE => { // Convert the nested flow sequence
                    line += check writeFlowSequence(state);
                }
                event:MAPPING => { // Convert the nested flow mapping
                    line += check writeFlowMapping(state);
                }
            }
        }

        line += ", ";
        event = getEvent(state);
    }

    // Trim the trailing separator
    line = line.length() > 2 ? line.substring(0, line.length() - 2) : line;
    line += "]";
    return line;
}

# Convert a block sequence into YAML string.
#
# + state - Current emitter state  
# + whitespace - Whitespace at the start of it
# + return - YAML string of the block sequence.
function writeBlockSequence(EmitterState state, string whitespace) returns EmittingError? {
    event:Event event = getEvent(state);
    boolean emptySequence = true;

    // Iterate until and end event is detected
    while true {
        if event is event:EndEvent {
            match event.endType {
                event:SEQUENCE|event:STREAM => { // Terminate for these events
                    if emptySequence {
                        state.output.push(whitespace + "-");
                    }
                    break;
                }
                event:MAPPING => { // End mapping events are not allowed
                    return generateError("Expected the block mapping to be terminated");
                }
            }
        }

        // Convert scalar event
        if event is event:ScalarEvent {
            state.output.push(string `${whitespace}- ${event.value.toString()}`);
        }

        // Check for nested collections
        if event is event:StartEvent {
            match event.startType {
                event:SEQUENCE => { // Convert the nested sequence
                    if event.flowStyle {
                        state.output.push(whitespace + "- " + check writeFlowSequence(state));
                    } else {
                        state.output.push(whitespace + "-");
                        check writeBlockSequence(state, whitespace + state.indent);
                    }
                }
                event:MAPPING => { // Convert the nested mapping
                    if event.flowStyle {
                        state.output.push(whitespace + "- " + check writeFlowMapping(state));
                    } else {
                        state.output.push(whitespace + "-");
                        check writeBlockMapping(state, whitespace + state.indent);
                    }
                }
            }
        }

        event = getEvent(state);
        emptySequence = false;
    }
}

import yaml.event;

# Convert a flow mapping into YAML string.
#
# + state - Current emitter state
# + return - YAML string of the flow mapping.
function writeFlowMapping(EmitterState state) returns string|EmittingError {
    string line = "{";
    event:Event event = getEvent(state);

    // Iterate until the end delimiter '}' is detected
    while true {
        if event is event:EndEvent {
            match event.endType {
                event:MAPPING => { // End delimiter is detected
                    break;
                }
                _ => { // Any other end events are not accepted
                    return generateError("Expected the flow mapping to be terminated");
                }
            }
        }

        // Convert a mapping key
        if event is event:ScalarEvent {
            line += event.value.toString() + ": ";
        }

        // Obtain the event for mapping value
        event = getEvent(state);

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
    line += "}";
    return line;
}

# Convert a block mapping into YAML string.
#
# + state - Current emitter state  
# + whitespace - Whitespace at the start of it
# + return - YAML string of the block mapping.
function writeBlockMapping(EmitterState state, string whitespace) returns EmittingError? {
    event:Event event = getEvent(state);
    string line;

    // Iterate until and end event is detected
    while true {
        line = "";
        if event is event:EndEvent {
            match event.endType {
                event:MAPPING|event:STREAM => { // Terminate for these events
                    break;
                }
                event:SEQUENCE => { // End sequence events are not allowed
                    return generateError("Expected the block mapping to be terminated");
                }
            }
        }

        // Convert the mapping key
        if event is event:ScalarEvent {
            line += whitespace + event.value.toString() + ": ";
        }

        // Obtain the event for mapping value
        event = getEvent(state);

        // Convert the scalar
        if event is event:ScalarEvent {
            line += event.value.toString();
            state.output.push(line);
        }

        // Check for nested collections
        if event is event:StartEvent {
            match event.startType {
                event:SEQUENCE => {
                    if event.flowStyle { // Convert the nested sequence
                        state.output.push(line + check writeFlowSequence(state));
                    } else {
                        state.output.push(line);
                        check writeBlockSequence(state, whitespace);
                    }
                }
                event:MAPPING => { // Convert the nested mapping
                    if event.flowStyle {
                        state.output.push(line + check writeFlowMapping(state));
                    } else {
                        state.output.push(line);
                        check writeBlockMapping(state, whitespace + state.indent);
                    }
                }
            }
        }

        line = "";
        event = getEvent(state);
    }
}

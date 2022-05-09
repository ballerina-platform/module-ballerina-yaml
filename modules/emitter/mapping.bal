import yaml.common;

# Convert a flow mapping into YAML string.
#
# + state - Current emitter state
# + tag - Tag of the start event if exists
# + return - YAML string of the flow mapping.
function writeFlowMapping(EmitterState state, string? tag) returns string|EmittingError {
    string line = writeNode(state, "{", tag);
    common:Event event = getEvent(state);

    // Iterate until the end delimiter '}' is detected
    while true {
        if event is common:EndEvent {
            match event.endType {
                common:MAPPING => { // End delimiter is detected
                    break;
                }
                _ => { // Any other end events are not accepted
                    return generateExpectedEndEventError(event, {endType: common:MAPPING});
                }
            }
        }

        // Convert a mapping key
        if event is common:ScalarEvent {
            line += writeNode(state, event.value, event.tag) + ": ";
        }

        // Obtain the event for mapping value
        event = getEvent(state);

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
# + tag - Tag of the start event if exists
# + return - YAML string of the block mapping.
function writeBlockMapping(EmitterState state, string whitespace, string? tag) returns EmittingError? {
    common:Event event = getEvent(state);
    string line;

    // Iterate until and end event is detected
    while true {
        line = "";
        if event is common:EndEvent {
            match event.endType {
                common:MAPPING|common:STREAM => { // Terminate for these events
                    break;
                }
                common:SEQUENCE => { // End sequence events are not allowed
                    return generateExpectedEndEventError(event, {endType: common:MAPPING});
                }
            }
        }

        // Convert the mapping key
        if event is common:ScalarEvent {
            line += whitespace + writeNode(state, event.value, event.tag) + ": ";
        }

        // Obtain the event for mapping value
        event = getEvent(state);

        // Convert the scalar
        if event is common:ScalarEvent {
            line += writeNode(state, event.value, event.tag);
            state.output.push(line);
        }

        // Check for nested collections
        if event is common:StartEvent {
            match event.startType {
                common:SEQUENCE => {
                    if event.flowStyle { // Convert the nested sequence
                        state.output.push(line + check writeFlowSequence(state, event.tag));
                    } else {
                        state.output.push(writeNode(state, line.substring(0, line.length() - 1), event.tag, true));
                        check writeBlockSequence(state, whitespace, event.tag);
                    }
                }
                common:MAPPING => { // Convert the nested mapping
                    if event.flowStyle {
                        state.output.push(line + check writeFlowMapping(state, event.tag));
                    } else {
                        state.output.push(writeNode(state, line.substring(0, line.length() - 1), event.tag, true));
                        check writeBlockMapping(state, whitespace + state.indent, event.tag);
                    }
                }
            }
        }

        line = "";
        event = getEvent(state);
    }
}

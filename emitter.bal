type EmitterState record {|
    string[] output;
    string indent;
    Event[] events;
|};

function emit(Event[] events, int indentationPolicy = 2) returns string[]|EmittingError {
    string indent = "";
    foreach int i in 1 ... indentationPolicy {
        indent += " ";
    }

    EmitterState state = {
        output: [],
        indent,
        events
    };

    while state.events.length() != 0 {
        check write(state);
    }

    return state.output;
}

function write(EmitterState state) returns EmittingError? {
    Event event = getEvent(state);

    // Write block sequence
    if event is StartEvent && event.startType == SEQUENCE {
        if event.flowStyle {
            state.output.push(check writeFlowSequence(state));
        } else {
            check writeBlockSequence(state, "");
        }
        return;
    }

    if event is StartEvent && event.startType == MAPPING {
        if event.flowStyle {
            state.output.push(check writeFlowMapping(state));
        } else {
            check writeBlockMapping(state, "");
        }
        return;
    }

    if event is ScalarEvent {
        state.output.push(event.value == () ? "" : event.value.toString());
        return;
    }
}

function writeFlowSequence(EmitterState state) returns string|EmittingError {
    string line = "[";
    Event event = getEvent(state);

    while true {
        if event is EndEvent {
            match event.endType {
                SEQUENCE|STREAM => {
                    break;
                }
            }
        }

        if event is ScalarEvent {
            line += event.value.toString();
        }

        if event is StartEvent {
            match event.startType {
                SEQUENCE => {
                    line += check writeFlowSequence(state);
                }
                MAPPING => {
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

function writeBlockSequence(EmitterState state, string whitespace) returns EmittingError? {
    Event event = getEvent(state);
    boolean emptySequence = true;

    while true {
        // Write scalar event
        if event is ScalarEvent {
            state.output.push(string `${whitespace}- ${event.value.toString()}`);
        }

        if event is EndEvent {
            match event.endType {
                SEQUENCE|STREAM => {
                    if emptySequence {
                        state.output.push(whitespace + "-");
                    }
                    break;
                }
            }
        }

        if event is StartEvent {
            match event.startType {
                SEQUENCE => {
                    if event.flowStyle {
                        state.output.push(whitespace + "- " + check writeFlowSequence(state));
                    } else {
                        state.output.push(whitespace + "-");
                        check writeBlockSequence(state, whitespace + state.indent);
                    }
                }
                MAPPING => {
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

function writeFlowMapping(EmitterState state) returns string|EmittingError {
    string line = "{";
    Event event = getEvent(state);

    while true {
        if event is EndEvent {
            match event.endType {
                MAPPING|STREAM => {
                    break;
                }
            }
        }

        if event is ScalarEvent {
            line += event.value.toString() + ": ";
        }

        event = getEvent(state);

        if event is ScalarEvent {
            line += event.value.toString();
        }

        if event is StartEvent {
            match event.startType {
                MAPPING => {
                    line += check writeFlowMapping(state);
                }
                SEQUENCE => {
                    line += check writeFlowSequence(state);
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

function writeBlockMapping(EmitterState state, string whitespace) returns EmittingError? {
    Event event = getEvent(state);
    string line;

    while true {
        line = "";
        if event is EndEvent {
            match event.endType {
                MAPPING|STREAM => {
                    break;
                }
            }
        }

        if event is ScalarEvent {
            line += whitespace + event.value.toString() + ": ";
        }

        event = getEvent(state);

        if event is ScalarEvent {
            line += event.value.toString();
            state.output.push(line);
        }

        if event is StartEvent {
            match event.startType {
                SEQUENCE => {
                    if event.flowStyle {
                        state.output.push(line + check writeFlowSequence(state));
                    } else {
                        state.output.push(line);
                        check writeBlockSequence(state, whitespace);
                    }
                }
                MAPPING => {
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

function getEvent(EmitterState state) returns Event {
    if state.events.length() < 1 {
        return {endType: STREAM};
    }
    return state.events.remove(0);
}

# Generates a Emitting Error.
#
# + message - Error message
# + return - Constructed Parsing Error message  
function generateError(string message) returns EmittingError {
    return error EmittingError(string `Emitting Error: ${message}.`);
}

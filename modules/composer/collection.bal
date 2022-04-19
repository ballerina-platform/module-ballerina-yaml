import yaml.event;
import yaml.parser;
import yaml.lexer;

# Compose the sequence collection into Ballerina array.
#
# + state - Current composer state
# + flowStyle - If a collection is flow sequence
# + return - Constructed Ballerina array on success
function composeSequence(ComposerState state, boolean flowStyle) returns json[]|lexer:LexicalError|parser:ParsingError|ComposingError {
    json[] sequence = [];
    event:Event event = check checkEvent(state);

    // Iterate until the end event is detected
    while true {
        if event is event:EndEvent {
            match event.endType {
                event:MAPPING => {
                    return generateError(state, "Expected a sequence end event");
                }
                event:SEQUENCE => {
                    break;
                }
                event:DOCUMENT|event:STREAM => {
                    state.docTerminated = event.endType == event:DOCUMENT;
                    if !flowStyle {
                        break;
                    }
                    return generateError(state, "Expected a sequence end event");
                }
            }
        }

        if event is event:DocumentStartEvent {
            if !flowStyle {
                break;
            }
            return generateError(state, "Expected a sequence end event");
        }

        sequence.push(check composeNode(state, event));
        event = check checkEvent(state);
    }

    return sequence;
}

# Compose the mapping collection into Ballerina map.
#
# + state - Current composer state
# + flowStyle - If a collection is flow mapping
# + return - Constructed Ballerina array on success
function composeMapping(ComposerState state, boolean flowStyle) returns map<json>|lexer:LexicalError|parser:ParsingError|ComposingError {
    map<json> structure = {};
    event:Event event = check checkEvent(state, parser:EXPECT_KEY);

    // Iterate until an end event is detected
    while true {
        if event is event:EndEvent {
            match event.endType {
                event:MAPPING => {
                    break;
                }
                event:SEQUENCE => {
                    return generateError(state, "Expected a mapping end event");
                }
                event:DOCUMENT|event:STREAM => {
                    state.docTerminated = event.endType == event:DOCUMENT;
                    if !flowStyle {
                        break;
                    }
                    return generateError(state, "Expected a mapping end event");
                }
            }
        }

        if event is event:DocumentStartEvent {
            if !flowStyle {
                break;
            }
            return generateError(state, "Expected a sequence end event");
        }

        if !(event is event:StartEvent|event:ScalarEvent) {
            return generateError(state, "Expected a key for a mapping");
        }

        // Compose the key
        json key = check composeNode(state, event);

        // Compose the value
        event = check checkEvent(state, parser:EXPECT_VALUE);
        json value = check composeNode(state, event);

        // Map the key value pair
        structure[key.toString()] = value;
        event = check checkEvent(state, parser:EXPECT_KEY);
    }

    return structure;
}

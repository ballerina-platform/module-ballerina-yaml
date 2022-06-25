import yaml.common;
import yaml.parser;
import yaml.lexer;
import yaml.schema;

# Compose the YAML sequence collection into Ballerina array.
#
# + state - Current composer state
# + flowStyle - If a collection is flow sequence
# + return - Constructed Ballerina array on success
function composeSequence(ComposerState state, boolean flowStyle) returns json[]|lexer:LexicalError|parser:ParsingError|ComposingError|schema:SchemaError {
    json[] sequence = [];
    common:Event event = check checkEvent(state, parser:EXPECT_SEQUENCE_VALUE);

    // Iterate until the end sequence event is detected
    while true {
        if event is common:DocumentMarkerEvent {
            state.terminatedDocEvent = event;
            if !flowStyle {
                break;
            }
            return generateExpectedEndEventError(state, "DOCUMENT", common:MAPPING);
        }

        if event is common:EndEvent {
            match event.endType {
                common:MAPPING => {
                    return generateExpectedEndEventError(state, common:MAPPING, common:SEQUENCE);
                }
                common:SEQUENCE => {
                    break;
                }
                common:STREAM => {
                    if !flowStyle {
                        break;
                    }
                    return generateExpectedEndEventError(state, common:STREAM, common:SEQUENCE);
                }
            }
        }
        sequence.push(check composeNode(state, event));
        event = check checkEvent(state, parser:EXPECT_SEQUENCE_ENTRY);
    }

    return (sequence == [] && !flowStyle) ? [null] : sequence;
}

# Compose the YAML mapping collection into Ballerina map.
#
# + state - Current composer state  
# + flowStyle - If a collection is flow mapping  
# + implicitMapping - Flag is set if there can only be one key-value pair
# + return - Constructed Ballerina array on success
function composeMapping(ComposerState state, boolean flowStyle, boolean implicitMapping) returns map<json>|lexer:LexicalError|parser:ParsingError|ComposingError|schema:SchemaError {
    map<json> structure = {};
    common:Event event = check checkEvent(state, parser:EXPECT_MAP_KEY);

    // Iterate until an end event is detected
    while true {
        if event is common:DocumentMarkerEvent {
            state.terminatedDocEvent = event;
            if !flowStyle {
                break;
            }
            return generateExpectedEndEventError(state, "DOCUMENT", common:MAPPING);
        }

        if event is common:EndEvent {
            match event.endType {
                common:MAPPING => {
                    break;
                }
                common:SEQUENCE => {
                    return generateExpectedEndEventError(state, common:SEQUENCE, common:MAPPING);
                }
                _ => {
                    if !flowStyle {
                        break;
                    }
                    return generateExpectedEndEventError(state, common:STREAM, common:MAPPING);
                }
            }
        }

        // Cannot have a nested block mapping if a value is assigned
        if event is common:StartEvent && !event.flowStyle {
            return generateComposeError(state,
                "Cannot have nested mapping under a key-pair that is already assigned",
                event);
        }

        // Compose the key
        json key = check composeNode(state, event);

        if !state.allowMapEntryRedefinition && structure.hasKey(key.toString()) {
            return generateComposeError(state, string `Cannot have duplicate map entries for '${key.toString()}'`, event);
        }

        // Compose the value
        event = check checkEvent(state, parser:EXPECT_MAP_VALUE);

        // Check for mapping end events
        if event is common:EndEvent {
            match event.endType {
                common:MAPPING => {
                    structure[key.toString()] = ();
                    break;
                }
                common:SEQUENCE => {
                    return generateExpectedEndEventError(state, common:SEQUENCE, common:MAPPING);
                }
                _ => {
                    if !flowStyle {
                        structure[key.toString()] = ();
                        break;
                    }
                    return generateExpectedEndEventError(state, common:STREAM, common:MAPPING);
                }
            }
        } else {
            structure[key.toString()] = check composeNode(state, event);
        }

        // Terminate after single key-value pair if implicit mapping flag is set.
        if implicitMapping {
            break;
        }

        event = check checkEvent(state, parser:EXPECT_MAP_KEY);
    }

    return structure;
}

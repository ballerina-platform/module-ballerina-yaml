import yaml.parser;
import yaml.common;
import yaml.schema;
import yaml.lexer;

# Compose the Ballerina data structure for the given node event.
#
# + state - Current composer state
# + event - Node event to be composed
# + return - Native Ballerina data on success
function composeNode(ComposerState state, common:Event event) returns json|lexer:LexicalError|parser:ParsingError|ComposingError|schema:SchemaError {
    json output;

    // Check for aliases
    if event is common:AliasEvent {
        return state.anchorBuffer.hasKey(event.alias)
            ? state.anchorBuffer[event.alias]
            : generateAliasingError(state, string `The anchor '${event.alias}' does not exist`, event);
    }

    // Ignore end events
    if event is common:EndEvent {
        return;
    }

    // Ignore document markers
    if event is common:DocumentMarkerEvent {
        state.terminatedDocEvent = event;
        return;
    }

    // Check for collections
    if event is common:StartEvent {
        output = {};
        match event.startType {
            common:SEQUENCE => { // Check for sequence
                output = check castData(state, check composeSequence(state, event.flowStyle), schema:SEQUENCE, event.tag);
            }
            common:MAPPING => { // Check for mapping
                output = check castData(state, check composeMapping(state, event.flowStyle, event.implicit), schema:MAPPING, event.tag);
            }
            _ => {
                return generateComposeError(state, "Only sequence and mapping are allowed as node start events", event);
            }
        }
        check checkAnchor(state, event, output);
        return output;
    }

    // Check for scalar
    output = check castData(state, event.value, schema:STRING, event.tag);
    check checkAnchor(state, event, output);
    return output;
}

# Update the alias dictionary for the given alias.
#
# + state - Current composer state  
# + event - The event representing the alias name 
# + assignedValue - Anchored value to to the alias
# + return - An error on failure
function checkAnchor(ComposerState state, common:StartEvent|common:ScalarEvent event, json assignedValue) returns ComposingError? {
    if event.anchor != () {
        if state.anchorBuffer.hasKey(<string>event.anchor) && !state.allowAnchorRedefinition {
            return generateAliasingError(state, string `Duplicate anchor definition of '${<string>event.anchor}'`, event);
        }
        state.anchorBuffer[<string>event.anchor] = assignedValue;
    }
}

# Construct the ballerina data structures from the failsafe schema data.
#
# + state - Current composer state
# + data - Original fail safe schema data
# + kind - Fail safe schema type
# + tag - Tag of the data if exists
# + return - Constructed ballerina data
function castData(ComposerState state, json data,
    schema:FailSafeSchema kind, string? tag) returns json|ComposingError|schema:SchemaError {
    // Check for explicit keys 
    if tag != () {
        // Check for the tags in the YAML failsafe schema
        if tag == schema:defaultGlobalTagHandle + "str" {
            return kind == schema:STRING
                ? data.toString()
                : generateExpectedKindError(state, kind, schema:STRING, tag);
        }

        if tag == schema:defaultGlobalTagHandle + "seq" {
            return kind == schema:SEQUENCE
                ? data
                : generateExpectedKindError(state, kind, schema:SEQUENCE, tag);
        }

        if tag == schema:defaultGlobalTagHandle + "map" {
            return kind == schema:MAPPING
                ? data
                : generateExpectedKindError(state, kind, schema:MAPPING, tag);
        }

        // Check for tags defined in the tag schema
        if !state.tagSchema.hasKey(tag) {
            return generateComposeError(state, string `There is no tag schema for '${tag}'`, data);
        }
        schema:YAMLTypeConstructor typeConstructor = state.tagSchema.get(tag);

        if kind != typeConstructor.kind {
            return generateExpectedKindError(state, kind, typeConstructor.kind, tag);
        }

        return typeConstructor.construct(data);
    }

    // Iterate all the tag schema
    string[] yamlKeys = state.tagSchema.keys();
    foreach string yamlKey in yamlKeys {
        schema:YAMLTypeConstructor typeConstructor = state.tagSchema.get(yamlKey);
        json|schema:SchemaError result = typeConstructor.construct(data);

        if result is schema:SchemaError || kind != typeConstructor.kind {
            continue;
        }

        return result;
    }

    // Return as a type of the YAML failsafe schema.
    return data;
}

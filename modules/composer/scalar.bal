import yaml.parser;
import yaml.event;
import yaml.lexer;

# Compose the native Ballerina data structure for the given node event.
#
# + state - Current composer state
# + event - Node event to be composed
# + return - Native Ballerina data on success
function composeNode(ComposerState state, event:Event event) returns json|lexer:LexicalError|parser:ParsingError|ComposingError {
    json output;

    // Check for collections
    if event is event:StartEvent {
        output = {};
        match event.startType {
            event:SEQUENCE => { // Check for +SEQ
                output = check composeSequence(state, event.flowStyle);
            }
            event:MAPPING => {
                output = check composeMapping(state, event.flowStyle);
            }
            _ => {
                return generateError(state, "Only sequence and mapping are allowed as node start events");
            }
        }
        check checkAnchor(state, event, output);
        return output;
    }

    // Check for aliases
    if event is event:AliasEvent {
        return state.anchorBuffer.hasKey(event.alias)
                ? state.anchorBuffer[event.alias]
                : generateError(state, string `The anchor '${event.alias}' does not exist`);
    }

    // Check for SCALAR
    if event is event:ScalarEvent {
        output = event.value;
        check checkAnchor(state, event, output);
        return output;
    }
}

# Update the alias dictionary for the given alias.
#
# + state - Current composer state  
# + event - The event representing the alias name 
# + assignedValue - Anchored value to to the alias
# + return - An error on failure
function checkAnchor(ComposerState state, event:StartEvent|event:ScalarEvent event, json assignedValue) returns ComposingError? {
    if event.anchor != () {
        if state.anchorBuffer.hasKey(<string>event.anchor) {
            return generateError(state, string `Duplicate anchor definition of '${<string>event.anchor}'`);
        }
        state.anchorBuffer[<string>event.anchor] = assignedValue;
    }
}

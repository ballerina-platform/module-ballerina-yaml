import yaml.schema;
import yaml.common;

# Represents the variables of the Emitter state.
#
# + output - Lines to be written.  
# + indent - Total whitespace for a single indent  
# + canonical - If set, the tag is written explicitly along with the value.
# + tagSchema - Custom tags for the YAML parser  
# + events - Event tree to be written
type EmitterState record {|
    string[] output;
    readonly string indent;
    readonly boolean canonical;
    readonly & map<schema:YAMLTypeConstructor> tagSchema;
    common:Event[] events;
|};

# Obtain the output string lines for given event trees.
#
# + events - Event tree to be converted  
# + indentationPolicy - Number of whitespace for an indent  
# + canonical - If set, the tag is written explicitly along with the value.
# + tagSchema - Custom tags for the YAML parser
# + isStream - Whether the event tree is a stream  
# + return - YAML string lines
public function emit(common:Event[] events,
    int indentationPolicy,
    boolean canonical,
    readonly & map<schema:YAMLTypeConstructor> tagSchema,
    boolean isStream) returns string[]|EmittingError {

    // Setup the total whitespace for an indentation
    string indent = "";
    foreach int i in 1 ... indentationPolicy {
        indent += " ";
    }

    EmitterState state = {
        output: [],
        indent,
        canonical,
        tagSchema,
        events
    };

    if isStream { // Write YAML stream
        while state.events.length() > 0 {
            check write(state);
            state.output.push("...");    
        }
    } else { // Write a single YAML document
        check write(state);
        if state.events.length() > 0 {
            return generateError("There can only be one root event for a document");
        }
    }

    return state.output;
}

# Convert a single YAML document to YAML strings
#
# + state - Current emitter state
# + return - An error on failure
function write(EmitterState state) returns EmittingError? {
    common:Event event = getEvent(state);

    // Convert sequence collection
    if event is common:StartEvent && event.startType == common:SEQUENCE {
        if event.flowStyle {
            state.output.push(check writeFlowSequence(state, event.tag));
        } else {
            check writeBlockSequence(state, "", event.tag);
        }
        return;
    }

    // Convert mapping collection
    if event is common:StartEvent && event.startType == common:MAPPING {
        if event.flowStyle {
            state.output.push(check writeFlowMapping(state, event.tag));
        } else {
            check writeBlockMapping(state, "", event.tag);
        }
        return;
    }

    // Convert scalar 
    if event is common:ScalarEvent {
        state.output.push(writeNode(state, event.value, event.tag));
        return;
    }
}

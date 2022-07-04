import yaml.common;

# Represents the variables of the Emitter state.
#
# + output - YAML content as an array of strings
# + customTagHandles - Custom tag handles that can be included in the directive document
# + indent - Total whitespace for a single indent  
# + canonical - If set, the tag is written explicitly along with the value
# + events - Event tree to be converted
type EmitterState record {|
    string[] output;
    map<string> customTagHandles;
    readonly string indent;
    readonly boolean canonical;
    common:Event[] events;
|};

# Obtain the output string lines for a given event tree.
#
# + events - Event tree to be converted  
# + customTagHandles - Custom tag handles that can be included in the directive document
# + indentationPolicy - Number of spaces for an indent  
# + canonical - If set, the tag is written explicitly along with the value
# + isStream - Whether the event tree is a stream
# + return - Output YAML content as an array of strings.
public function emit(common:Event[] events,
    map<string> customTagHandles,
    int indentationPolicy,
    boolean canonical,
    boolean isStream) returns string[]|EmittingError {

    // Setup the total whitespace for an indentation
    string indent = "";
    foreach int i in 1 ... indentationPolicy {
        indent += " ";
    }

    EmitterState state = {
        output: [],
        customTagHandles,
        indent,
        canonical,
        events
    };

    if isStream { // Write YAML stream
        while state.events.length() > 0 {
            check write(state);
            state.output.push("---");
        }
    } else { // Write a single YAML document
        check write(state);
        if state.events.length() > 0 {
            return generateEmittingError("There can only be one root event for a document", getEvent(state));
        }
    }

    return state.output;
}

# Convert a single YAML document to array of YAML strings
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

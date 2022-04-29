import yaml.schema;
import yaml.event;

# Represents the variables of the Emitter state.
#
# + output - Lines to be written.
# + indent - Total whitespace for a single indent  
# + events - Event tree to be written
type EmitterState record {|
    string[] output;
    readonly string indent;
    readonly boolean canonical;
    map<schema:YAMLTypeConstructor> tagSchema;
    event:Event[] events;
|};

# Obtain the output string lines for given event trees.
#
# + events - Event tree to be converted  
# + indentationPolicy - Number of whitespace for an indent  
# + isStream - Whether the event tree is a stream
# + return - YAML string lines
public function emit(event:Event[] events,
    int indentationPolicy,
    map<schema:YAMLTypeConstructor> tagSchema,
    boolean isStream = false,
    boolean canonical = false) returns string[]|EmittingError {

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
        // TODO: Write YAML streams
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
    event:Event event = getEvent(state);

    // Convert sequence collection
    if event is event:StartEvent && event.startType == event:SEQUENCE {
        if event.flowStyle {
            state.output.push(check writeFlowSequence(state));
        } else {
            check writeBlockSequence(state, "");
        }
        return;
    }

    // Convert mapping collection
    if event is event:StartEvent && event.startType == event:MAPPING {
        if event.flowStyle {
            state.output.push(check writeFlowMapping(state));
        } else {
            check writeBlockMapping(state, "");
        }
        return;
    }

    // Convert scalar 
    if event is event:ScalarEvent {
        state.output.push(reduceTagHandle(event.tag) + " " + event.value.toString());
        return;
    }
}

# Obtain the topmost event from the event tree.
#
# + state - Current emitter state
# + return - The topmost event from the current tree.
function getEvent(EmitterState state) returns event:Event {
    if state.events.length() < 1 {
        return {endType: event:STREAM};
    }
    return state.events.shift();
}

function reduceTagHandle(string? tag) returns string {
    if tag == () {
        return "";
    }

    string[] keys = schema:defaultTagHandles.keys();

    string tagHandleReference;
    foreach string key in keys {
        tagHandleReference = schema:defaultTagHandles.get(key);
        if tag.startsWith(tagHandleReference) {
            return key + tag.substring(tagHandleReference.length());
        }
    }

    return string `!<${tag}>`;
}

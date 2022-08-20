import yaml.common;

# Obtain the output string lines for a given event tree.
#
# + state - Parameter Description  
# + isStream - Whether the event tree is a stream
# + return - Output YAML content as an array of strings.
public function emit(EmitterState state, boolean isStream) returns string[]|EmittingError {
    if isStream { // Write YAML stream
        string[] output = [];
        while state.events.length() > 0 {
            check write(state);
            state.getDocument(true).forEach(line => output.push(line));
        }
        return output;
    } else { // Write a single YAML document
        check write(state);
        if state.events.length() > 0 {
            return generateEmittingError("There can only be one root event for a document", getEvent(state));
        }
        return state.getDocument();
    }
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
            state.addLine(check writeFlowSequence(state, event.tag));
        } else {
            check writeBlockSequence(state, "", event.tag);
        }
        return;
    }

    // Convert mapping collection
    if event is common:StartEvent && event.startType == common:MAPPING {
        if event.flowStyle {
            state.addLine(check writeFlowMapping(state, event.tag));
        } else {
            check writeBlockMapping(state, "", event.tag);
        }
        return;
    }

    // Convert scalar 
    if event is common:ScalarEvent {
        state.addLine(writeNode(state, event.value, event.tag));
        return;
    }
}

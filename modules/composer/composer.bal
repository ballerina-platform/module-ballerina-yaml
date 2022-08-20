import yaml.parser;
import yaml.common;

# Compose single YAML document to Ballerina.
#
# + state - Initiated composer state  
# + eventParam - Passed root event if already fetched
# + return - Ballerina data structure on success
public function composeDocument(ComposerState state, common:Event? eventParam = ()) returns json|ComposingError {
    // Obtain the root event
    common:Event event = eventParam is () ? check checkEvent(state, docType = parser:ANY_DOCUMENT) : eventParam;

    // Ignore the start document marker for explicit documents
    if event is common:DocumentMarkerEvent && event.explicit {
        event = check checkEvent(state, docType = parser:ANY_DOCUMENT);
    }

    // Construct the single document
    json output = check composeNode(state, event);

    // Return an error if there is another root event
    event = check checkEvent(state);
    if event is common:EndEvent && event.endType == common:STREAM {
        return output;
    }
    if event is common:DocumentMarkerEvent {
        state.terminatedDocEvent = event;
        return output;
    }
    return generateComposeError(state, "There can only be one root event to a document", event);
}

# Compose a stream YAML documents to an array of Ballerina structures.
#
# + state - Initiated composer state  
# + return - Native Ballerina data structure on success
public function composeStream(ComposerState state) returns json[]|ComposingError {
    json[] output = [];
    common:Event event = check checkEvent(state, docType = parser:ANY_DOCUMENT);

    // Iterate all the documents
    while !(event is common:EndEvent && event.endType == common:STREAM) {
        output.push(check composeDocument(state, event));

        if state.terminatedDocEvent is common:DocumentMarkerEvent {
            // Explicit document markers should be passed to the composeDocument
            if (<common:DocumentMarkerEvent>state.terminatedDocEvent).explicit {
                event = <common:DocumentMarkerEvent>state.terminatedDocEvent;
                state.terminatedDocEvent = ();
            } else { // All the trailing document end markers should be ignored
                state.terminatedDocEvent = ();
                event = check checkEvent(state, docType = parser:ANY_DOCUMENT);

                while event is common:DocumentMarkerEvent && !event.explicit {
                    event = check checkEvent(state, docType = parser:ANY_DOCUMENT);
                }
            }
        } else { // Obtain the stream end event
            event = check checkEvent(state, docType = parser:ANY_DOCUMENT);
        }
    }

    return output;
}

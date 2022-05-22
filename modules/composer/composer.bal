import yaml.parser;
import yaml.common;

# Compose single YAML document to native Ballerina structure.
#
# + state - Initiated composer state  
# + eventParam - Passed the expected event if already fetched
# + return - Native Ballerina data structure on success
public function composeDocument(ComposerState state, common:Event? eventParam = ()) returns json|ComposingError {
    // Obtain the root event
    common:Event event = eventParam is () ? check checkEvent(state, docType = parser:ANY_DOCUMENT) : eventParam;

    // Ignore the markers at the start of the document
    while event is common:EndEvent && event.endType == common:DOCUMENT {
        event = check checkEvent(state, docType = parser:ANY_DOCUMENT);
    }

    // Construct the single document
    json output = check composeNode(state, event);

    // Return an error if there is another root event
    event = check checkEvent(state);
    return isEndOfDocument(event) ? output
            : generateComposeError(state, "There can only be one root event to a document", event);
}

# Compose a stream YAML documents to an array of native Ballerina structure.
#
# + state - Initiated composer state  
# + return - Native Ballerina data structure on success
public function composeStream(ComposerState state) returns json[]|ComposingError {
    json[] output = [];
    common:Event event = check checkEvent(state);

    // Iterate all the documents
    while !(event is common:EndEvent && event.endType == common:STREAM) {
        output.push(check composeDocument(state, event));
        state.docTerminated = false;
        event = check checkEvent(state);
    }

    return output;
}

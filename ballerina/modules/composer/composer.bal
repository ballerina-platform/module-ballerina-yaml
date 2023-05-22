// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import yaml.parser;
import yaml.common;

# Compose single YAML document to Ballerina.
#
# + state - Initiated composer state  
# + eventParam - Passed root event if already fetched
# + return - Ballerina data structure on success
public isolated function composeDocument(ComposerState state, common:Event? eventParam = ()) returns json|ComposingError {
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
public isolated function composeStream(ComposerState state) returns json[]|ComposingError {
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

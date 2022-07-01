import yaml.common;
import yaml.schema;

# Generates the event tree for the given Ballerina native data structure.
#
# + state - Current serializing state  
# + data - Ballerina native data structure  
# + depthLevel - The current depth level  
# + excludeTag - The tag to be excluded when obtaining the YAML type
# + return - Event tree. Else, an error on failure.
public function serialize(SerializerState state, json data, int depthLevel = 0, string? excludeTag = ())
    returns common:Event[]|schema:SchemaError {

    common:Event[] events = [];
    string? tag = ();
    schema:YAMLTypeConstructor? typeConstructor = ();

    // Obtain the tag
    schema:YAMLTypeConstructor currentTypeConstructor;
    string[] tagKeys = state.tagSchema.keys();
    foreach string key in tagKeys {
        if excludeTag is string && excludeTag == key {
            continue;
        }
        currentTypeConstructor = <schema:YAMLTypeConstructor>state.tagSchema[key];

        if currentTypeConstructor.identity(data) {
            tag = key;
            typeConstructor = currentTypeConstructor;
            break;
        }
    }

    // Serialize the event based on the custom YAML tag
    if typeConstructor is schema:YAMLTypeConstructor && tag is string {
        if typeConstructor.kind == schema:SEQUENCE { // Convert sequence
            json[]|error sequence = typeConstructor.represent(data).ensureType();
            if sequence is error {
                return generateInvalidRepresentError(schema:SEQUENCE, tag);
            }
            return serializeSequence(state, events, sequence, tag, depthLevel);
        }
        if typeConstructor.kind == schema:MAPPING { // Convert mapping
            map<json>|error mapping = typeConstructor.represent(data).ensureType();
            if mapping is error {
                return generateInvalidRepresentError(schema:MAPPING, tag);
            }
            return serializeMapping(state, events, mapping, tag, depthLevel);
        }
        // Convert string
        return serializeString(state, events, check typeConstructor.represent(data), tag);
    }

    // Serialize an event with a failsafe schema tag by default
    if data is json[] { // Convert sequence
        return serializeSequence(state, events, data, string `${schema:defaultGlobalTagHandle}seq`, depthLevel);
    }
    if data is map<json> { // Convert mapping
        return serializeMapping(state, events, data, string `${schema:defaultGlobalTagHandle}map`, depthLevel);
    }
    // Convert string
    return serializeString(state, events, data, string `${schema:defaultGlobalTagHandle}str`);

}

# Combines two event trees together
#
# + firstEventsList - First event tree  
# + secondEventsList - Second event tree
# + return - Combined event tree
function combineArray(common:Event[] firstEventsList, common:Event[] secondEventsList) returns common:Event[] {
    common:Event[] returnEventsList = firstEventsList.clone();

    secondEventsList.forEach(function(common:Event event) {
        returnEventsList.push(event);
    });

    return returnEventsList;
}

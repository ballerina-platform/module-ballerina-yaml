import yaml.schema;

# Generates the event tree for the given Ballerina native data structure.
#
# + state - Current serializing state  
# + data - Ballerina native data structure  
# + depthLevel - The current depth level  
# + excludeTag - The tag to be excluded when obtaining the YAML type
# + return - Event tree. Else, an error on failure.
public function serialize(SerializerState state, json data, int depthLevel = 0, string? excludeTag = ())
    returns schema:SchemaError? {

    // Obtain the tag
    string? tag = ();
    schema:YAMLTypeConstructor? typeConstructor = ();
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
                return generateInvalidRepresentError(tag, schema:SEQUENCE);
            }
            check serializeSequence(state, sequence, tag, depthLevel);
        }
        else if typeConstructor.kind == schema:MAPPING { // Convert mapping
            map<json>|error mapping = typeConstructor.represent(data).ensureType();
            if mapping is error {
                return generateInvalidRepresentError(tag, schema:MAPPING);
            }
            check serializeMapping(state, mapping, tag, depthLevel);
        } else { // Convert string
            serializeString(state, check typeConstructor.represent(data), tag);
        }
    } else { // Serialize an event with a failsafe schema tag by default
        if data is json[] { // Convert sequence
            check serializeSequence(state, data, string `${schema:defaultGlobalTagHandle}seq`, depthLevel);
        } else if data is map<json> { // Convert mapping
            check serializeMapping(state, data, string `${schema:defaultGlobalTagHandle}map`, depthLevel);
        } else { // Convert string
            serializeString(state, data, string `${schema:defaultGlobalTagHandle}str`);
        }
    }
}

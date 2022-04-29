import yaml.event;
import yaml.schema;

# Generates the event tree for the given Ballerina native data structure.
#
# + data - Ballerina native data structure
# + blockLevel - The depth of the block nodes 
# + depthLevel - The current depth level
# + return - Event tree. Else, an error on failure.
public function serialize(json data, map<schema:YAMLTypeConstructor> tagSchema, int blockLevel,
    int depthLevel = 0) returns event:Event[]|SerializingError {
    event:Event[] events = [];

    string? tag = ();

    // Obtain the tag
    string[] tagKeys = tagSchema.keys();
    foreach string key in tagKeys {
        schema:YAMLTypeConstructor typeConstructor = <schema:YAMLTypeConstructor>tagSchema[key];

        if typeConstructor.identity(data) {
            tag = key;
            break;
        }
    }

    // Convert sequence
    if data is json[] {
        events.push({startType: event:SEQUENCE, flowStyle: blockLevel <= depthLevel, tag});

        foreach json dataItem in data {
            events = combineArray(events, check serialize(dataItem, tagSchema, blockLevel, depthLevel + 1));
        }

        events.push({endType: event:SEQUENCE});
        return events;
    }

    // Convert mapping
    if data is map<json> {
        events.push({startType: event:MAPPING, flowStyle: blockLevel <= depthLevel, tag});

        string[] keys = data.keys();
        foreach string key in keys {
            events.push({value: key});
            events = combineArray(events, check serialize(data[key], tagSchema, blockLevel, depthLevel + 1));
        }

        events.push({endType: event:MAPPING});
        return events;
    }

    // Convert string
    events.push({value: data.toString(), tag});
    return events;
}

# Combines two event trees together
#
# + firstEventsList - First event tree  
# + secondEventsList - Second event tree
# + return - Combined event tree
function combineArray(event:Event[] firstEventsList, event:Event[] secondEventsList) returns event:Event[] {
    event:Event[] returnEventsList = firstEventsList.clone();

    secondEventsList.forEach(function(event:Event event) {
        returnEventsList.push(event);
    });

    return returnEventsList;
}

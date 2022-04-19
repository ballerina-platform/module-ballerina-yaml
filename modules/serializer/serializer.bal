import yaml.event;

# Generates the event tree for the given Ballerina native data structure.
#
# + data - Ballerina native data structure
# + blockLevel - The depth of the block nodes 
# + depthLevel - The current depth level
# + return - Event tree. Else, an error on failure.
public function serialize(json data, int blockLevel, int depthLevel = 0) returns event:Event[]|SerializingError {
    event:Event[] events = [];
    // TODO: check if the data is a custom tag

    // TODO: check if the current schema is CORE_SCHEMA

    // TODO: check if the current schema is JSON_SCHEMA

    // Convert sequence
    if data is json[] {
        events.push({startType: event:SEQUENCE, flowStyle: blockLevel <= depthLevel});

        foreach json dataItem in data {
            events = combineArray(events, check serialize(dataItem, blockLevel, depthLevel + 1));
        }

        events.push({endType: event:SEQUENCE});
        return events;
    }

    // Convert mapping
    if data is map<json> {
        events.push({startType: event:MAPPING, flowStyle: blockLevel <= depthLevel});

        string[] keys = data.keys();
        foreach string key in keys {
            events.push({value: key});
            events = combineArray(events, check serialize(data[key], blockLevel, depthLevel + 1));
        }

        events.push({endType: event:MAPPING});
        return events;
    }

    // Convert string
    // TODO: check the tag type
    events.push({value: data.toString()});
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

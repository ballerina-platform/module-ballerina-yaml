import yaml.common;
import ballerina/regex;
import yaml.schema;

const string INVALID_PLANAR_PATTERN = "([\\w|\\s]*[\\-|\\?|:|] [\\w|\\s]*)|"
    + "([\\w|\\s]* #[\\w|\\s]*)|"
    + "([\\,|\\[|\\]|\\{|\\}|&\\*|!\\||\\>|\\'|\\\"|%|@|\\`][\\w|\\s]*)";

# Generates the event tree for the given Ballerina native data structure.
#
# + state - Current serializing state
# + data - Ballerina native data structure  
# + depthLevel - The current depth level
# + return - Event tree. Else, an error on failure.
public function serialize(SerializerState state, json data, int depthLevel = 0)
    returns common:Event[]|schema:SchemaError {

    common:Event[] events = [];
    string? tag = ();
    schema:YAMLTypeConstructor? typeConstructor = ();

    // Obtain the tag
    schema:YAMLTypeConstructor currentTypeConstructor;
    string[] tagKeys = state.tagSchema.keys();
    foreach string key in tagKeys {
        currentTypeConstructor = <schema:YAMLTypeConstructor>state.tagSchema[key];

        if currentTypeConstructor.identity(data) {
            tag = key;
            typeConstructor = currentTypeConstructor;
            break;
        }
    }

    // Convert sequence
    if data is json[] {
        if typeConstructor is schema:YAMLTypeConstructor {
            events.push({tag, value: check typeConstructor.represent(data)});
            return events;
        } else {
            tag = string `${schema:defaultGlobalTagHandle}seq`;

            events.push({startType: common:SEQUENCE, flowStyle: state.blockLevel <= depthLevel, tag});

            foreach json dataItem in data {
                events = combineArray(events, check serialize(state, dataItem, depthLevel + 1));
            }

            events.push({endType: common:SEQUENCE});
            return events;
        }

    }

    // Convert mapping
    if data is map<json> {
        tag = typeConstructor == () ? string `${schema:defaultGlobalTagHandle}map` : tag;
        events.push({startType: common:MAPPING, flowStyle: state.blockLevel <= depthLevel, tag});

        string[] keys = data.keys();
        foreach string key in keys {
            events = combineArray(events, check serialize(state, key, depthLevel));
            events = combineArray(events, check serialize(state, data[key], depthLevel + 1));
        }

        events.push({endType: common:MAPPING});
        return events;
    }

    // Convert string
    string value;
    if typeConstructor is schema:YAMLTypeConstructor {
        value = check typeConstructor.represent(data);
    } else {
        tag = string `${schema:defaultGlobalTagHandle}str`;
        value = data.toString();
    }

    events.push({
        value: regex:matches(value, INVALID_PLANAR_PATTERN) || state.forceQuotes
            ? string `${state.delimiter}${value}${state.delimiter}` : value,
        tag
    });
    return events;
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

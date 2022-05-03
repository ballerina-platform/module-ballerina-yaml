import yaml.event;
import ballerina/regex;
import yaml.schema;

const string SPACE_AFTER = "[\\w|\\s]*[\\-|\\?|:|] [\\w|\\s]*";
const string SPACE_BEFORE = "[\\w|\\s]* #[\\w|\\s]*";
const string START_INDICATOR = "[\\,|\\[|\\]|\\{|\\}|&\\*|!\\||\\>|\\'|\\\"|%|@|\\`][\\w|\\s]*";

# Generates the event tree for the given Ballerina native data structure.
#
# + data - Ballerina native data structure  
# + tagSchema - Custom YAML tags for the parser
# + blockLevel - The depth of the block nodes  
# + delimiter - The type of quotes used to surround scalar values
# + forceQuotes - Only use quotes for scalar values
# + depthLevel - The current depth level
# + return - Event tree. Else, an error on failure.
public function serialize(json data, map<schema:YAMLTypeConstructor> tagSchema, int blockLevel,
    string:Char delimiter, boolean forceQuotes, int depthLevel = 0) returns event:Event[]|SerializingError {
    event:Event[] events = [];

    string? tag = ();
    schema:YAMLTypeConstructor? typeConstructor = ();

    // Obtain the tag
    schema:YAMLTypeConstructor currentTypeConstructor;
    string[] tagKeys = tagSchema.keys();
    foreach string key in tagKeys {
        currentTypeConstructor = <schema:YAMLTypeConstructor>tagSchema[key];

        if currentTypeConstructor.identity(data) {
            tag = key;
            typeConstructor = currentTypeConstructor;
            break;
        }
    }

    // Convert sequence
    if data is json[] {
        tag = typeConstructor == () ? string `${schema:defaultGlobalTagHandle}seq` : tag;
        events.push({startType: event:SEQUENCE, flowStyle: blockLevel <= depthLevel, tag});

        foreach json dataItem in data {
            events = combineArray(events, check serialize(dataItem, tagSchema, blockLevel, delimiter, forceQuotes, depthLevel + 1));
        }

        events.push({endType: event:SEQUENCE});
        return events;
    }

    // Convert mapping
    if data is map<json> {
        tag = typeConstructor == () ? string `${schema:defaultGlobalTagHandle}map` : tag;
        events.push({startType: event:MAPPING, flowStyle: blockLevel <= depthLevel, tag});

        string[] keys = data.keys();
        foreach string key in keys {
            events = combineArray(events, check serialize(key, tagSchema, blockLevel, delimiter, forceQuotes, depthLevel));
            events = combineArray(events, check serialize(data[key], tagSchema, blockLevel, delimiter, forceQuotes, depthLevel + 1));
        }

        events.push({endType: event:MAPPING});
        return events;
    }

    // Convert string
    string invalidPlanarRegexPattern = string `(${SPACE_AFTER})|(${SPACE_BEFORE})|(${START_INDICATOR})`;
    tag = typeConstructor == () ? string `${schema:defaultGlobalTagHandle}str` : tag;
    string value = typeConstructor == () ? data.toString() : (<schema:YAMLTypeConstructor>typeConstructor).represent(data);

    events.push({
        value: regex:matches(value, invalidPlanarRegexPattern) || forceQuotes
            ? string `${delimiter}${value}${delimiter}` : value,
        tag
    });
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

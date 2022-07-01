import yaml.common;
import yaml.schema;
import ballerina/regex;

const string INVALID_PLANAR_PATTERN = "([\\w|\\s]*[\\-|\\?|:|] [\\w|\\s]*)|"
    + "([\\w|\\s]* #[\\w|\\s]*)|"
    + "([\\,|\\[|\\]|\\{|\\}|&\\*|!\\||\\>|\\'|\\\"|%|@|\\`][\\w|\\s]*)";

function serializeString(SerializerState state, common:Event[] events, json data, string tag)
    returns common:Event[]|schema:SchemaError {
    string value = data.toString();
    events.push({
        value: regex:matches(value, INVALID_PLANAR_PATTERN) || state.forceQuotes
                ? string `${state.delimiter}${value}${state.delimiter}` : value,
        tag
    });
    return events;
}

function serializeSequence(SerializerState state, common:Event[] events, json[] data, string tag, int depthLevel)
    returns common:Event[]|schema:SchemaError {
    common:Event[] clonedEvents = events.clone();

    clonedEvents.push({startType: common:SEQUENCE, flowStyle: state.blockLevel <= depthLevel, tag});

    foreach json dataItem in data {
        clonedEvents = combineArray(clonedEvents, check serialize(state, dataItem, depthLevel + 1, tag));
    }

    clonedEvents.push({endType: common:SEQUENCE});
    return clonedEvents;
}

function serializeMapping(SerializerState state, common:Event[] events, map<json> data, string tag, int depthLevel)
    returns common:Event[]|schema:SchemaError {
    common:Event[] clonedEvents = events.clone();

    clonedEvents.push({startType: common:MAPPING, flowStyle: state.blockLevel <= depthLevel, tag});

    string[] keys = data.keys();
    foreach string key in keys {
        clonedEvents = combineArray(clonedEvents, check serialize(state, key, depthLevel, tag));
        clonedEvents = combineArray(clonedEvents, check serialize(state, data[key], depthLevel + 1, tag));
    }

    clonedEvents.push({endType: common:MAPPING});
    return clonedEvents;
}

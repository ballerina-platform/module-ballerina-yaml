import yaml.common;
import yaml.schema;
import ballerina/regex;

const string INVALID_PLANAR_PATTERN = "([\\w|\\s]*[\\-|\\?|:|] [\\w|\\s]*)|"
    + "([\\w|\\s]* #[\\w|\\s]*)|"
    + "([\\,|\\[|\\]|\\{|\\}|&\\*|!\\||\\>|\\'|\\\"|%|@|\\`][\\w|\\s]*)";

function serializeString(SerializerState state, json data, string tag) {
    string value = data.toString();
    state.events.push({
        value: regex:matches(value, INVALID_PLANAR_PATTERN) || state.forceQuotes
                ? string `${state.delimiter}${value}${state.delimiter}` : value,
        tag
    });
}

function serializeSequence(SerializerState state, json[] data, string tag, int depthLevel) returns schema:SchemaError? {
    // Block sequence does not have a syntax to represent an empty array.
    // Hence, the data should be forced to flow style.
    state.events.push({startType: common:SEQUENCE, flowStyle: state.blockLevel <= depthLevel || data == [], tag});

    foreach json dataItem in data {
        check serialize(state, dataItem, depthLevel + 1, tag);
    }

    state.events.push({endType: common:SEQUENCE});
}

function serializeMapping(SerializerState state, map<json> data, string tag, int depthLevel) returns schema:SchemaError? {
    state.events.push({startType: common:MAPPING, flowStyle: state.blockLevel <= depthLevel, tag});

    string[] keys = data.keys();
    foreach string key in keys {
        check serialize(state, key, depthLevel, tag);
        check serialize(state, data[key], depthLevel + 1, tag);
    }

    state.events.push({endType: common:MAPPING});
}

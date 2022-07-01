import yaml.common;
import yaml.schema;

function getSerializedEvents(json data, map<schema:YAMLTypeConstructor> tagSchema = {}, string:Char delimiter = "\"",
    boolean forceQuotes = false, int blockLevel = 1) returns common:Event[]|schema:SchemaError {

    SerializerState state = {events: [], tagSchema, delimiter, forceQuotes, blockLevel};
    check serialize(state, data);
    return state.events;
}

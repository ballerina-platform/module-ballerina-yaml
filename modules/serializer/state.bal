import yaml.common;
import yaml.schema;

# Represents the variables to outline the state of the serializer.
#
# + events - Serialized event tree  
# + tagSchema - Custom YAML tags for the parser  
# + delimiter - The type of quotes used to surround scalar values  
# + forceQuotes - Only use quotes for scalar values  
# + blockLevel - The depth of the block nodes
public type SerializerState record {|
    common:Event[] events;
    map<schema:YAMLTypeConstructor> tagSchema;
    readonly string:Char delimiter;
    readonly boolean forceQuotes;
    readonly int blockLevel;
|};

import yaml.schema;

# Represents the variables to outline the state of the serializer.
#
# + tagSchema - Custom YAML tags for the parser
# + delimiter - The type of quotes used to surround scalar values
# + forceQuotes - Only use quotes for scalar values
# + blockLevel - The depth of the block nodes  
public type SerializerState record {|
    map<schema:YAMLTypeConstructor> tagSchema;
    readonly string:Char delimiter;
    readonly boolean forceQuotes;
    readonly int blockLevel;
|};

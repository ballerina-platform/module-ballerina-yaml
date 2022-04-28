import yaml.schema;

# Configurations for writing a YAML document.
#
# + indentationPolicy - Number of whitespace for an indentation  
# + blockLevel - The maximum depth level for a block collection.  
# + schema - YAML schema used for writing  
# + yamlTypes - Custom YAML types for the schema
public type WriteConfig record {|
    int indentationPolicy = 2;
    int blockLevel = 1;
    YAMLSchema schema = CORE_SCHEMA;
    YAMLType[] yamlTypes = [];
|};

# Configurations for reading a YAML document.
#
# + schema - YAML schema used for writing
# + yamlTypes - Custom YAML types for the schema
public type ReadConfig record {|
    YAMLSchema schema = CORE_SCHEMA;
    YAMLType[] yamlTypes = [];
|};

# Represents the attributes of the custom YAML type.
#
# + tag - YAML tag for the custom type
public type YAMLType record {|
    string tag;
    *schema:YAMLTypeConstructor;
|};

public enum FailSafeSchema {
    MAPPING,
    SEQUENCE,
    STRING
}

public enum YAMLSchema {
    FAILSAFE_SCHEMA,
    JSON_SCHEMA,
    CORE_SCHEMA
}

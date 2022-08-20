public const string defaultLocalTagHandle = "!";
public const string defaultGlobalTagHandle = "tag:yaml.org,2002:";

public final readonly & map<string> defaultTagHandles = {
    "!": defaultLocalTagHandle,
    "!!": defaultGlobalTagHandle
};

public enum FailSafeSchema {
    MAPPING,
    SEQUENCE,
    STRING
}

# Represents the attributes to support bi-directional conversion between YAML and Ballerina.
#
# + kind - Fail safe schema type
# + construct - Function to generate the Ballerina data structure.  
# + identity - Function to check if the data adheres the custom YAML type.
# + represent - Function to convert the Ballerina data structure to YAML.
public type YAMLTypeConstructor record {|
    FailSafeSchema kind;
    function (json data) returns json|SchemaError construct;
    function (json data) returns boolean identity;
    function (json data) returns json|SchemaError represent;
|};


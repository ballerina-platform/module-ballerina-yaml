import yaml.common;

# Represents an error caused regarding YAML schema.
public type SchemaError ConstructionError|common:ConversionError;

# Represents an error caused when constructing a Ballerina data type.
public type ConstructionError distinct error;

# Generates a Type Error.
#
# + message - Error message details
# + return - Constructed Type Error message
function generateError(string message) returns ConstructionError =>
    error ConstructionError(message);

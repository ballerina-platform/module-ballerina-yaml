import yaml.common;

# Represents an error caused during the serializing.
public type SerializingError distinct error<common:WriteErrorDetails>;

# Generates a Serializing Error.
#
# + message - Error message  
# + actualValue - Invalid value which causes the error
# + return - Constructed Serializing Error message
function generateError(string message, json actualValue) returns SerializingError =>
    error(message, actual = actualValue);

# Represents an error caused when casting the type.
public type TypeError distinct error;

# Generates a Type Error.
#
# + message - Error message details
# + return - Constructed Type Error message
function generateError(string message) returns TypeError =>
    error TypeError(string `Typing Error: ${message}`);

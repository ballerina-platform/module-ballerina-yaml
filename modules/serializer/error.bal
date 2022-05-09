# Represents an error caused during the serializing.
public type SerializingError distinct error;

# Generates a Serializing Error.
#
# + message - Error message
# + return - Constructed Serializing Error message  
function generateError(string message) returns SerializingError => error(message);

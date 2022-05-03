# Represents an error caused by serializer
type SerializingError distinct error;

# Generates a Serializing Error.
#
# + message - Error message
# + return - Constructed Serializing Error message  
function generateError(string message) returns SerializingError {
    return error SerializingError(string `Serializing Error: ${message}.`);
}

# Represents an error caused by serializer
type SerializingError distinct error;

# Generates a Parsing Error.
#
# + message - Error message
# + return - Constructed Parsing Error message  
function generateError(string message) returns SerializingError {
    return error SerializingError(string `Serializing Error: ${message}.`);
}

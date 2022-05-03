# Represents an error caused by emitter
type EmittingError distinct error;

# Generates a Emitting error.
#
# + message - Error message
# + return - Constructed Emitting error message  
function generateError(string message) returns EmittingError {
    return error EmittingError(string `Emitting Error: ${message}.`);
}

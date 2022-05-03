# Represents an error caused by composer
type ComposingError distinct error;

# Generates a Composing error.
#
# + state - Current composer state  
# + message - Error message
# + return - Constructed Composing error message
function generateError(ComposerState state, string message) returns ComposingError {
    string text = "Composing Error at line "
                        + (state.parserState.getLineNumber() + 1).toString()
                        + " index "
                        + state.parserState.getIndex().toString()
                        + ": "
                        + message
                        + ".";
    return error ComposingError(text);
}

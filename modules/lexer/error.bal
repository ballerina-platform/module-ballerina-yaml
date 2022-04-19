# Represents an error caused by the lexical analyzer
type LexicalError distinct error;

# Generates a Lexical Error.
#
# + state - Current lexer state  
# + message - Error message
# + return - Constructed Lexical Error message
function generateError(LexerState state, string message) returns LexicalError {
    string text = "Lexical Error at line "
                        + (state.lineNumber + 1).toString()
                        + " index "
                        + state.index.toString()
                        + ": "
                        + message
                        + ".";
    return error LexicalError(text);
}

# Generate the template error message "Invalid character '${char}' for a '${token}'"
#
# + character - Current character  
# + value - Expected token name or the value
# + return - Generated error message
function formatErrorMessage(string character, string value) returns string
    => string `Invalid character '${character}' for a '${value}'`;


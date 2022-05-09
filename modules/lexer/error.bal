import yaml.common;

# Represents an error caused by the lexical analyzer
public type LexicalError ScanningError|common:IndentationError;

# Represents an error that is generated when an invalid character for a lexeme is detected.
public type ScanningError distinct error<common:ReadErrorDetails>;

# Generate an error message based on the template error message
# "Invalid character '${char}' for a '${token}'"
#
# + state - Current lexer state  
# + context - Context of the lexeme being scanned
# + return - Generated error message
function generateInvalidCharacterError(LexerState state, string context) returns ScanningError {
    string:Char currentChar = <string:Char>state.peek();
    string message = string `Invalid character '${currentChar}' for a '${context}'.`;
    return error ScanningError(
        message,
        line = state.lineNumber + 1,
        column = state.index,
        actual = currentChar
    );
}

function generateScanningError(LexerState state, string message) returns ScanningError =>
    error ScanningError(
        message + ".",
        line = state.lineNumber + 1,
        column = state.index,
        actual = <string:Char>state.peek()
    );

function generateIndentationError(LexerState state, string message) returns common:IndentationError =>
    error common:IndentationError(
        message + ".",
        line = state.lineNumber + 1,
        column = state.index,
        actual = <string:Char>state.peek()
    );

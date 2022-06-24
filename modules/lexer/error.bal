import yaml.common;

# Represents an error caused during the lexical analyzing.
public type LexicalError ScanningError|common:IndentationError|common:ConversionError;

# Represents an error that is generated when an invalid character for a lexeme is detected.
public type ScanningError distinct error<common:ReadErrorDetails>;

# Generate an error message based on the template,
# "Invalid character '${char}' for a '${token}'"
#
# + state - Current lexer state  
# + context - Context of the lexeme being scanned
# + return - Generated error message
function generateInvalidCharacterError(LexerState state, string context) returns ScanningError {
    string? currentChar = state.peek();
    string message = string `Invalid character '${currentChar ?: "<end-of-line>"}' for a '${context}'.`;
    return error(
        message,
        line = state.lineNumber + 1,
        column = state.index,
        actual = currentChar
    );
}

function generateScanningError(LexerState state, string message) returns ScanningError =>
    error(
        message + ".",
        line = state.lineNumber + 1,
        column = state.index,
        actual = state.peek()
    );

function generateIndentationError(LexerState state, string message) returns common:IndentationError =>
    error(
        message + ".",
        line = state.lineNumber + 1,
        column = state.index,
        actual = state.peek()
    );

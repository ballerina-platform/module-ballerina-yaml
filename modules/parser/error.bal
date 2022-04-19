import yaml.lexer;

# Represents an error caused by parser
type ParsingError distinct error;

# Generates a Parsing Error.
#
# + state - Current parser state
# + message - Error message
# + return - Constructed Parsing Error message  
function generateError(ParserState state, string message) returns ParsingError {
    string text = "Parsing Error at line "
                        + state.lexerState.lineNumber.toString()
                        + " index "
                        + state.lexerState.index.toString()
                        + ": "
                        + message
                        + ".";
    return error ParsingError(text);
}

# Generate a standard error message of "Expected ${expectedTokens} after ${beforeToken}, but found ${actualToken}"
#
# + currentToken - Current token 
# + expectedTokens - Expected tokens for the grammar production
# + beforeToken - Token before the current one
# + return - Formatted error message
function formatExpectErrorMessage(lexer:YAMLToken currentToken, lexer:YAMLToken|lexer:YAMLToken[]|string expectedTokens, lexer:YAMLToken beforeToken) returns string {
    string expectedTokensMessage;
    if (expectedTokens is lexer:YAMLToken[]) { // If multiple tokens
        string tempMessage = expectedTokens.reduce(function(string message, lexer:YAMLToken token) returns string {
            return message + " '" + token + "' or";
        }, "");
        expectedTokensMessage = tempMessage.substring(0, tempMessage.length() - 3);
    } else { // If a single token
        expectedTokensMessage = " '" + <string>expectedTokens + "'";
    }
    return string `Expected '${expectedTokensMessage}'  after '${beforeToken}', but found '${currentToken}'`;
}

# Generate a standard error message of "Duplicate key exists for ${value}"
#
# + value - Any value name. Commonly used to indicate keys.  
# + valueType - Possible types - key, table, value
# + return - Formatted error message
function formateDuplicateErrorMessage(string value, string valueType = "key") returns string
    => string `Duplicate ${valueType} exists for '${value}'`;

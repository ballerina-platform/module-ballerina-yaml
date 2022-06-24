import yaml.common;
import yaml.lexer;

# Represents an error caused during the parsing.
public type ParsingError GrammarError|lexer:LexicalError|
    common:IndentationError|common:AliasingError|common:ConversionError;

# Represents an error caused for an invalid grammar production.
public type GrammarError distinct error<common:ReadErrorDetails>;

# Generate an error message based on the template,
# "Expected ${expectedTokens} after ${beforeToken}, but found ${actualToken}"
#
# + state - Current parser state
# + expectedTokens - Expected tokens for the grammar production  
# + beforeToken - Token before the current one
# + return - Formatted error message
function generateExpectError(ParserState state,
    lexer:YAMLToken|lexer:YAMLToken[]|string expectedTokens, lexer:YAMLToken beforeToken) returns ParsingError {

    string expectedTokensMessage;
    if expectedTokens is lexer:YAMLToken[] { // If multiple tokens
        string tempMessage = expectedTokens.reduce(function(string message, lexer:YAMLToken token) returns string {
            return message + " '" + token + "' or";
        }, "");
        expectedTokensMessage = tempMessage.substring(0, tempMessage.length() - 3);
    } else { // If a single token
        expectedTokensMessage = " '" + <string>expectedTokens + "'";
    }
    string message =
        string `Expected${expectedTokensMessage} after '${beforeToken}', but found '${state.currentToken.token}'`;

    return generateGrammarError(state, message, expectedTokens);
}

# Generate an error message based on the template,
# "Duplicate key exists for ${value}"
#
# + state - Current parser state
# + value - Any value name. Commonly used to indicate keys.  
# + valueType - Possible types - key, table, value
# + return - Formatted error message
function generateDuplicateError(ParserState state, string value, string valueType = "key") returns GrammarError
    => generateGrammarError(state, string `Duplicate ${valueType} exists for '${value}'`);

# Generate an error message based on the template,
# "Invalid token '${actual}' inside the ${production}"
#
# + state - Current parser state
# + production - Production at which the invalid token appear
# + return - Formatted error message
function generateInvalidTokenError(ParserState state, string production) returns GrammarError
    => generateGrammarError(state, string `Invalid token '${state.currentToken.token}' inside the ${production}`, context = production);

function generateGrammarError(ParserState state, string message,
    json? expected = (), json? context = ()) returns GrammarError
        => error(
            message + ".",
            line = state.getLineNumber(),
            column = state.lexerState.index,
            actual = state.currentToken.token,
            expected = expected
        );

function generateIndentationError(ParserState state, string message) returns common:IndentationError
    => error(
        message + ".",
        line = state.getLineNumber(),
        column = state.lexerState.index,
        actual = state.currentToken.token
    );

function generateAliasingError(ParserState state, string message) returns common:AliasingError
    => error(
        message + ".",
        line = state.getLineNumber(),
        column = state.lexerState.index,
        actual = state.currentToken.token
    );

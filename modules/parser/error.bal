// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import yaml.common;
import yaml.lexer;

# Represents an error caused during the parsing.
public type ParsingError GrammarError|lexer:LexicalError|common:AliasingError|common:ConversionError;

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

function generateAliasingError(ParserState state, string message) returns common:AliasingError
    => error(
        message + ".",
        line = state.getLineNumber(),
        column = state.lexerState.index,
        actual = state.currentToken.token
    );

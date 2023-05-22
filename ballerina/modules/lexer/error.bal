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
isolated function generateInvalidCharacterError(LexerState state, string context) returns ScanningError {
    string? currentChar = state.peek();
    string message = string `Invalid character '${currentChar ?: "<end-of-line>"}' for a '${context}'.`;
    return error(
        message,
        line = state.lineNumber + 1,
        column = state.index,
        actual = currentChar
    );
}

isolated function generateScanningError(LexerState state, string message) returns ScanningError =>
    error(
        message + ".",
        line = state.lineNumber + 1,
        column = state.index,
        actual = state.peek()
    );

isolated function generateIndentationError(LexerState state, string message) returns common:IndentationError =>
    error(
        message + ".",
        line = state.lineNumber + 1,
        column = state.index,
        actual = state.peek()
    );

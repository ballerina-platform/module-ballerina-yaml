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

import yaml.parser;
import yaml.lexer;
import yaml.common;
import yaml.schema;

# Represents an error caused during the composing.
public type ComposingError ComposeError|parser:ParsingError|lexer:LexicalError|
    schema:SchemaError|common:AliasingError;

# Represents an error caused for an invalid compose.
public type ComposeError distinct error<common:ReadErrorDetails>;

# Generate an error message based on the template,
# "Expected '${expectedEvent}' before '-${actualEvent}'"
#
# + state - Current composer state  
# + actualEvent - Obtained invalid event
# + expectedEvent - Next expected event of the stream
# + return - Formatted error message
function generateExpectedEndEventError(ComposerState state,
    string actualEvent, string expectedEvent) returns ComposeError =>
        generateComposeError(state, common:generateExpectedEndEventErrorMessage(actualEvent, expectedEvent),
            actualEvent, expectedEvent);

# Generate an error message based on the template,
# Expected '${expectedKind}' kind for the '${tag}' tag but found '${actualKind}'
#
# + state - Current parser state  
# + actualKind - Actual core schema kind of the data  
# + expectedKind - Expected core schema kind of the data
# + tag - Tag of the data
# + return - Formatted error message
function generateExpectedKindError(ComposerState state, string actualKind, string expectedKind, string tag)
    returns ComposeError => generateComposeError(
        state,
        string `Expected '${expectedKind}' kind for the '${tag}' tag but found '${actualKind}'`,
        actualKind,
        expectedKind);

function generateAliasingError(ComposerState state, string message, common:Event actualEvent)
    returns common:AliasingError =>
        error(
            message,
            line = state.parserState.getLineNumber(),
            column = state.parserState.getIndex(),
            actual = actualEvent
        );

function generateComposeError(ComposerState state, string message, json actualEvent, json? expectedEvent = ()) returns ComposeError =>
    error(
        message,
        line = state.parserState.getLineNumber(),
        column = state.parserState.getIndex(),
        actual = actualEvent,
        expected = expectedEvent
    );


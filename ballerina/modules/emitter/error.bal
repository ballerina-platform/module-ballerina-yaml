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

# Represents an error caused during the emitting.
public type EmittingError distinct error<common:WriteErrorDetails>;

# Generate an error message based on the template,
# "Expected '-${expectedEvent}' before '-${actualEvent}'"
#
# + actualEvent - Obtained invalid event
# + expectedEvent - Next expected event of the stream
# + return - Formatted error message
isolated function generateExpectedEndEventError(string actualEvent, string expectedEvent) returns EmittingError =>
    generateEmittingError(common:generateExpectedEndEventErrorMessage(actualEvent, expectedEvent),
        actualEvent, expectedEvent);

isolated function generateEmittingError(string message, json actualValue, json? expectedValue = ())
    returns EmittingError =>
        error(
            message,
            actual = actualValue,
            expected = expectedValue
        );

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

import ballerina/io;

# Generate an error for conversion fault between Ballerina and YAML.
#
# + message - Cause of the error message
# + return - Formatted error message
public isolated function generateConversionError(string message) returns ConversionError => error(message);

# Check errors during type casting to Ballerina types.
#
# + value - Value to be type casted.
# + return - Value as a Ballerina data type  
public isolated function processTypeCastingError(json|error value) returns json|ConversionError {
    // Check if the type casting has any errors
    if value is error {
        return generateConversionError(value.message());
    }

    // Returns the value on success
    return value;
}

# Generate the string error message of the template,
# "Expected '${expectedEvent}' before '-${actualEvent}'"
#
# + actualEvent - Obtained invalid event
# + expectedEvent - Next expected event of the stream
# + return - Formatted error message as a string
public isolated function generateExpectedEndEventErrorMessage(string actualEvent, string expectedEvent) returns string
    => string `Expected '-${expectedEvent}' before '-${actualEvent}'`;

# Convert the string to a string array.
#
# + inputStr - Input string to be converted
# + return - String array of the input string
public isolated function convertStringToLines(string inputStr) returns string[] {
    do {
        io:ReadableByteChannel readableChannel = check io:createReadableChannel(inputStr.toBytes());
        io:ReadableCharacterChannel readableCharChannel = new (readableChannel, io:DEFAULT_ENCODING);
        return check readableCharChannel.readAllLines();
    } on fail {
        return [inputStr];
    }
}

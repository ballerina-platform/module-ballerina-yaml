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

# Validate the construction of the Ballerina data via a regex pattern.
#
# + regexPattern - Regex pattern used for validation
# + data - Data to be converted to the appropriate structure.
# + typeName - Type name to be displayed in the error message.
# + construct - Function to construct the Ballerina data structure.
# + return - Constructed Ballerina data structure.
function constructWithRegex(string regexPattern,
    json data,
    string typeName,
    function (string) returns json|SchemaError construct) returns json|SchemaError {

    if re `${regexPattern}`.isFullMatch(data.toString()) {
        return construct(data.toString());
    }
    return generateError(string `Cannot cast '${data.toJsonString()}' to '${typeName}'`);
}

# Simply represent the value as it is as string.
#
# + data - Data to represent
# + return - String value for the json data.
function representAsString(json data) returns string =>
    data.toString();

# Generate a function that confirms the type of the data.
#
# + typeDesc - Type to be asserted with the given data
# + return - Function to validate the data
public isolated function generateIdentityFunction(typedesc<json> typeDesc) returns function (json data) returns boolean {
    return function(json data) returns boolean {
        json|error output = data.ensureType(typeDesc);
        return output == data;
    };
}

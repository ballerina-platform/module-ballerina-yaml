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

public const string defaultLocalTagHandle = "!";
public const string defaultGlobalTagHandle = "tag:yaml.org,2002:";

public final readonly & map<string> defaultTagHandles = {
    "!": defaultLocalTagHandle,
    "!!": defaultGlobalTagHandle
};

public enum FailSafeSchema {
    MAPPING,
    SEQUENCE,
    STRING
}

# Represents the attributes to support bi-directional conversion between YAML and Ballerina.
#
# + kind - Fail safe schema type
# + construct - Function to generate the Ballerina data structure.  
# + identity - Function to check if the data adheres the custom YAML type.
# + represent - Function to convert the Ballerina data structure to YAML.
public type YAMLTypeConstructor record {|
    FailSafeSchema kind;
    isolated function (json data) returns json|SchemaError construct;
    isolated function (json data) returns boolean identity;
    isolated function (json data) returns json|SchemaError represent;
|};


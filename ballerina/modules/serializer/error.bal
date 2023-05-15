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

import yaml.schema;

# Generate an error message based on the template,
# Error while representing the tag '${tag}'. Expected the return type to be '${kind}'.
#
# + tag - The tag which has the invalid represent function
# + kind - Expected return type of the represent function
# + return - Formatted error message
isolated function generateInvalidRepresentError(string tag, string kind)
    returns schema:SchemaError => error(
        string `Error while representing the tag '${tag}'. Expected the return type to be '${kind}'.`,
        expected = kind);

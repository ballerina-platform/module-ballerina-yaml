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
import yaml.schema;

# Represents the variables to outline the state of the serializer.
#
# + events - Serialized event tree  
# + tagSchema - Custom YAML tags for the parser  
# + delimiter - The type of quotes used to surround scalar values  
# + forceQuotes - Only use quotes for scalar values  
# + blockLevel - The depth of the block nodes
public type SerializerState record {|
    common:Event[] events;
    map<schema:YAMLTypeConstructor> tagSchema;
    readonly string:Char delimiter;
    readonly boolean forceQuotes;
    readonly int blockLevel;
|};

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
import yaml.parser;
import ballerina/lang.regexp;

isolated function serializeString(SerializerState state, json data, string tag) {
    string value = data.toString();
    if value.includes("\n") {
        value = state.delimiter + regexp:replaceAll(re `\n`, data.toString(), "\\n") + state.delimiter;
    } else {
        value = (!parser:isValidPlanarScalar(value) || state.forceQuotes) ? state.delimiter + value + state.delimiter : value;
    }
    state.events.push({value, tag});
}

isolated function serializeSequence(SerializerState state, json[] data, string tag, int depthLevel) returns schema:SchemaError? {
    // Block sequence does not have a syntax to represent an empty array.
    // Hence, the data should be forced to flow style.
    state.events.push({startType: common:SEQUENCE, flowStyle: state.blockLevel <= depthLevel || data == [], tag});

    foreach json dataItem in data {
        check serialize(state, dataItem, depthLevel + 1, tag);
    }

    state.events.push({endType: common:SEQUENCE});
}

isolated function serializeMapping(SerializerState state, map<json> data, string tag, int depthLevel) returns schema:SchemaError? {
    state.events.push({startType: common:MAPPING, flowStyle: state.blockLevel <= depthLevel, tag});

    string[] keys = data.keys();
    foreach string key in keys {
        check serialize(state, key, depthLevel, tag);
        check serialize(state, data[key], depthLevel + 1, tag);
    }

    state.events.push({endType: common:MAPPING});
}

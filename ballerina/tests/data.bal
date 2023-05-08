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

import ballerina/file;
import ballerina/io;

function yamlDataGen() returns map<[string, json, boolean, boolean]>|error {
    file:MetaData[] data = check file:readDir("tests/resources");
    map<[string, json, boolean, boolean]> testMetaData = {};

    // Read the directory of the test cases
    foreach file:MetaData item in data {
        if !item.dir {
            continue;
        }
        file:MetaData[] testFiles = check file:readDir(item.absPath);
        string dirName = item.absPath.substring(<int>item.absPath.indexOf("resources") + 10);

        if testFiles[0].dir {
            foreach file:MetaData subItem in testFiles {
                int pathLength = subItem["absPath"].length();
                string:Char dirChar = subItem["absPath"][pathLength - 4];
                check addTestCase(testMetaData, subItem, dirName,
                    "#" + ((dirChar == "/" || dirChar == "\\")
                        ? subItem["absPath"].substring(pathLength - 3)
                        : subItem["absPath"].substring(pathLength - 2)));
            }
        }
        else {
            check addTestCase(testMetaData, item, dirName);
        }
    }

    return testMetaData;
}

function addTestCase(map<[string, json, boolean, boolean]> testMetaData, file:MetaData metaData, string dirName, string? annexData = ()) returns error? {
    string dirPath = metaData.absPath + "/";
    string testCase = string `${dirName}${annexData ?: ""}-${check io:fileReadString(dirPath + "===")}`;
    string yamlPath = dirPath + "in.yaml";
    string jsonPath = dirPath + "in.json";
    boolean isStream = check file:test(dirPath + "stream", file:EXISTS);
    boolean isError = false;
    json expectedOutput = ();
    if check file:test(jsonPath, file:EXISTS) {
        expectedOutput = check io:fileReadJson(jsonPath);
    }
    else {
        isError = true;
    }

    testMetaData[testCase] = [yamlPath, expectedOutput, isStream, isError];
}

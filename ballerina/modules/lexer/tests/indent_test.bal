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

import ballerina/test;

@test:Config {
    groups: ["lexer"],
    dataProvider: indentationInputDataGen
}
function testIndentationOfBlockCollection(string[] lines) returns error? {
    [int, int][] indentData = [[0, 1], [2, 2], [5, 3], [0, 1]];
    LexerState state = new ();
    foreach int i in 0 ... 3 {
        state.setLine(lines[i], i);
        state = check scan(state);
        Token token = state.getToken();

        while token.indentation == () {
            state = check scan(state);
            token = state.getToken();
        }

        test:assertEquals(state.indent, indentData[i][0]);
        test:assertEquals(state.indents.length(), indentData[i][1]);
    }
}

function indentationInputDataGen() returns map<[string[]]> {
    return {
        "mapping": [["first:", "  second:", "     third:", "forth:"]],
        "sequence": [["-", "  -", "     -", "-"]],
        "mixed": [["-", "  second:", "     -", "forth:"]]
    };
}

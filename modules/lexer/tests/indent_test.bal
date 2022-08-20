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

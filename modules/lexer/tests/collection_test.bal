import ballerina/test;

@test:Config {}
function testIndentationOfBlockMapping() returns error? {
    string[] lines = ["first:", "  second:", "     third:", "forth:"];
    [int, int][] indentMapping = [[0, 1], [2, 2], [5, 3], [0, 1]];

    LexerState state = new ();
    foreach int i in 0 ... 3 {
        state.line = lines[i];
        state.index = 0;
        state = check scan(state);
        Token token = state.getToken();

        while token.token != PLANAR_CHAR {
            state = check scan(state);
            token = state.getToken();
        }

        test:assertEquals(state.indent, indentMapping[i][0]);
        test:assertEquals(state.indents.length(), indentMapping[i][1]);
    }
}

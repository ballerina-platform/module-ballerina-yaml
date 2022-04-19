import ballerina/test;

@test:Config {
    dataProvider: doubleQuoteLineBreakDataGen
}
function testDoubleQuoteLineBreakEvent(string[] arr, string value) returns error? {
    check assertParsingEvent(arr, value);
}

function doubleQuoteLineBreakDataGen() returns map<[string[], string]> {
    return {
        "flow-folded": [["\"folded ", "to a space,   ", " ", "to a line feed\""], "folded to a space,\nto a line feed"],
        "escaped-line-break": [["\"folded to \\", " non-content\""], "folded to  non-content"],
        "first-line-space": [["\"space \""], "space "]
    };
}
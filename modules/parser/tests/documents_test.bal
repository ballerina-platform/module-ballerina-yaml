import ballerina/test;

@test:Config {}
function testKeyMapSpanningMultipleValues() returns error? {
    check assertParsingEvent(["", " ", "", " value"], "value");
}
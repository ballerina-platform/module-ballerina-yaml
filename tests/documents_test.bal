import ballerina/test;

@test:Config {
    dataProvider: documentMarkersDataGen
}

function testDocumentMarkerToken(string lexeme, YAMLToken token) returns error? {
    Lexer lexer = setLexerString(lexeme);
    check assertToken(lexer, token);
}

function documentMarkersDataGen() returns map<[string, YAMLToken]> {
    return {
        "directive-marker": ["---", DIRECTIVE_MARKER],
        "document-marker": ["...", DOCUMENT_MARKER]
    };
}

@test:Config {}
function testKeyMapSpanningMultipleValues() returns error? {
    check assertParsingEvent(["", " ", "", " value"], "value");
}
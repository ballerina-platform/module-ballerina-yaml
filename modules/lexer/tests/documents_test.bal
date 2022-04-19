import ballerina/test;

@test:Config {
    dataProvider: documentMarkersDataGen
}

function testDocumentMarkerToken(string lexeme, YAMLToken token) returns error? {
    LexerState state = setLexerString(lexeme);
    check assertToken(state, token);
}

function documentMarkersDataGen() returns map<[string, YAMLToken]> {
    return {
        "directive-marker": ["---", DIRECTIVE_MARKER],
        "document-marker": ["...", DOCUMENT_MARKER]
    };
}
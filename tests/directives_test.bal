import ballerina/test;

@test:Config {
    dataProvider: directiveDataGen,
    groups: ["directives"]
}
function testDirectivesToken(string lexeme, string value) returns error? {
    Lexer lexer = setLexerString(lexeme);
    check assertToken(lexer, DIRECTIVE, lexeme = value);
}

function directiveDataGen() returns map<[string, string]> {
    return {
        "yaml-directive": ["%YAML", "YAML"],
        "tag-directive": ["%TAG", "TAG"]
    };
}

@test:Config {
    groups: ["directives"]
}
function testAccurateYAMLDirective() returns error? {
    Parser parser = check new Parser(["%YAML 1.3", "---"]);
    _ = check parser.parse(docType = ANY_DOCUMENT);

    test:assertEquals(parser.yamlVersion, "1.3");
}

@test:Config {
    groups: ["directives"]
}
function testDuplicateYAMLDirectives() returns error?{
    check assertParsingError(["%YAML 1.3", "%YAML 1.1"]);
}

@test:Config {
    dataProvider: invalidDirectiveDataGen,
    groups: ["directives"]
}
function testInvalidYAMLDirectives(string line) returns error? {
    check assertParsingError(line);
}

function invalidDirectiveDataGen() returns map<[string]> {
    return {
        "additional dot": ["%YAML 1.2.1"],
        "no space": ["%YAML1.2"],
        "single digit": ["%YAML 1"]
    };
}

@test:Config {
    dataProvider: validTagDataGen
}
function testValidTagHandlers(string tag, string lexeme) returns error? {
    Lexer lexer = setLexerString(tag, LEXER_TAG_HANDLE);
    check assertToken(lexer, TAG_HANDLE, lexeme = lexeme);
}

function validTagDataGen() returns map<[string, string]> {
    return {
        "primary": ["! ", "!"],
        "secondary": ["!! ", "!!"],
        "named": ["!named! ", "!named!"]
    };
}

@test:Config {
    dataProvider: tagPrefixDataGen
}
function testTagPrefixTokens(string lexeme, string value) returns error? {
    Lexer lexer = setLexerString(lexeme, LEXER_TAG_PREFIX);
    check assertToken(lexer, TAG_PREFIX, lexeme = value);
}

function tagPrefixDataGen() returns map<[string, string]> {
    return {
        "local-tag-prefix": ["!local- ", "!local-"],
        "global-tag-prefix": ["tag:example.com,2000:app/  ", "tag:example.com,2000:app/"],
        "global-tag-prefix starting hex": ["%21global  ", "!global"],
        "global-tag-prefix inline hex": ["global%21hex  ", "global!hex"],
        "global-tag-prefix single-hex": ["%21  ", "!"]
    };
}

@test:Config {
    dataProvider: invalidUriHexDataGen
}
function testInvalidURIHexCharacters(string lexeme) returns error? {
    assertLexicalError(lexeme, state = LEXER_TAG_PREFIX);
}

function invalidUriHexDataGen() returns map<[string]> {
    return {
        "one digit": ["%a"],
        "no digit": ["%"],
        "two %": ["%1%"]
    };
}

@test:Config {}
function testTagDuplicates() returns error? {
    check assertParsingError(["%TAG !a! firstPrefix ", "%TAG !a! secondPrefix "]);
}

@test:Config {
    dataProvider: tagHandlesDataGen
}
function testTagHandles(string line, string tagHandle, string tagPrefix) returns error? {
    Parser parser = check new Parser([line, "---"]);
    _ = check parser.parse(docType = ANY_DOCUMENT);
    test:assertEquals(parser.tagHandles[tagHandle], tagPrefix);
}

function tagHandlesDataGen() returns map<[string, string, string]> {
    return {
        "primary": ["%TAG ! local ", "!", "local"],
        "secondary": ["%TAG !! tag:global ", "!!", "tag:global"],
        "named": ["%TAG !a! tag:named ", "!a!", "tag:named"]
    };
}

@test:Config {}
function testInvalidContentInDirectiveDocument() returns error? {
    check assertParsingError(["%TAG ! local", "anything that is not %"]);
}

@test:Config {}
function testInvalidDirectiveInBareDocument() returns error?{
    Parser parser = check new (["---", "%TAG ! local"]);

    _ = check parser.parse(docType = ANY_DOCUMENT);
    error|Event err = parser.parse();

    test:assertTrue(err is ParsingError);
}
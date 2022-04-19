import ballerina/test;
import yaml.event;
import yaml.lexer;

function assertParsingEvent(string|string[] lines, string value = "", string tag = "", string tagHandle = "", string anchor = "") returns error? {
    event:Event event = check parse(check new ParserState((lines is string) ? [lines] : lines));

    if value.length() > 0 {
        test:assertEquals((<event:ScalarEvent>event).value, value);
    }

    if tag.length() > 0 {
        test:assertEquals((<event:ScalarEvent>event).tag, tag);
    }

    if anchor.length() > 0 {
        test:assertEquals((<event:ScalarEvent>event).anchor, anchor);
    }

    if tagHandle.length() > 0 {
        test:assertEquals((<event:ScalarEvent>event).tagHandle, tagHandle);
    }
}

# Assert if an parsing error is generated during the parsing
#
# + lines - Lines to be parsed.  
# + isLexical - If set, checks for Lexical errors. Else, checks for Parsing errors.  
# + eventNumber - Number of times to parse before the error is generated.
# + return - An parsing error if the line is empty.
function assertParsingError(string|string[] lines, boolean isLexical = false, int eventNumber = 1) returns error? {
    ParserState state = check new ((lines is string) ? [lines] : lines);

    event:Event|error err;

    foreach int i in 1 ... eventNumber {
        err = parse(state, docType = ANY_DOCUMENT);
    }

    if (isLexical) {
        test:assertTrue(err is lexer:LexicalError);
    } else {
        test:assertTrue(err is ParsingError);
    }

}

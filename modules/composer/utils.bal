import yaml.parser;
import yaml.event;
import yaml.lexer;

# Obtain the next event
#
# + state - Current composer state  
# + option - Expected parser option  
# + docType - Expected YAML document
# + return - Next event on success
function checkEvent(ComposerState state, parser:ParserOption option = parser:DEFAULT, parser:DocumentType docType = parser:BARE_DOCUMENT) returns event:Event|lexer:LexicalError|parser:ParsingError {
    if state.docTerminated {
        return {endType: event:DOCUMENT};
    }
    return parser:parse(state.parserState, option, docType);
}

# Check if the end of the document is reached
#
# + event - Current event
# + return - True if the end of the document is reached
function isEndOfDocument(event:Event event) returns boolean => event is event:EndEvent && (event.endType == event:STREAM || event.endType == event:DOCUMENT);

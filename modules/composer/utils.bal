import yaml.parser;
import yaml.common;
import yaml.lexer;

# Obtain the next event
#
# + state - Current composer state  
# + option - Expected parser option  
# + docType - Expected YAML document
# + return - Next event on success
function checkEvent(ComposerState state, parser:ParserOption option = parser:DEFAULT,
    parser:DocumentType docType = parser:BARE_DOCUMENT) returns common:Event|lexer:LexicalError|parser:ParsingError {
    
    if state.terminatedDocEvent is common:DocumentMarkerEvent {
        return <common:DocumentMarkerEvent>state.terminatedDocEvent;
    }
    return parser:parse(state.parserState, option, docType);
}

# Check if the end of the document is reached
#
# + event - Current event
# + return - True if the end of the document is reached
function isEndOfDocument(common:Event event) returns boolean =>
    (event is common:EndEvent && event.endType == common:STREAM) || event is common:DocumentMarkerEvent;

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

import yaml.parser;
import yaml.event;

# Represents the state of the Composer
public class ComposerState {
    parser:ParserState parserState;
    event:Event? buffer = ();
    map<json> anchorBuffer = {};
    boolean docTerminated = false;

    public function init(string[] lines) returns parser:ParsingError? {
        self.parserState = check new (lines);
    }
}

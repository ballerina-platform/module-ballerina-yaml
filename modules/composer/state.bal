import yaml.parser;
import yaml.schema;
import yaml.event;

# Represents the state of the Composer
public class ComposerState {
    parser:ParserState parserState;
    event:Event? buffer = ();
    map<json> anchorBuffer = {};
    boolean docTerminated = false;
    map<schema:YAMLTypeConstructor> tagSchema = {};

    public function init(string[] lines, map<schema:YAMLTypeConstructor> tagSchema) returns parser:ParsingError? {
        self.parserState = check new (lines);
        self.tagSchema = tagSchema;
    }
}

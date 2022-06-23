import yaml.parser;
import yaml.common;
import yaml.schema;

# Represents the state of the Composer
public class ComposerState {
    # Current parser state.
    parser:ParserState parserState;

    # Hash map of the anchor to the respective Ballerina data.
    map<json> anchorBuffer = {};

    # Flag is set if the end of the document is reached.
    common:DocumentMarkerEvent? terminatedDocEvent = ();

    # Custom tag schema for the YAML parser.
    map<schema:YAMLTypeConstructor> tagSchema = {};

    public function init(string[] lines, map<schema:YAMLTypeConstructor> tagSchema) returns parser:ParsingError? {
        self.parserState = check new (lines);
        self.tagSchema = tagSchema;
    }
}

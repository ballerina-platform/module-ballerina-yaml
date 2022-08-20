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

    # Flag is set if anchors can be redefined multiple times
    readonly & boolean allowAnchorRedefinition;

    # Flag is set if same map keys are allowed in a mapping
    readonly & boolean allowMapEntryRedefinition;

    public function init(string[] lines, map<schema:YAMLTypeConstructor> tagSchema,
        boolean allowAnchorRedefinition, boolean allowMapEntryRedefinition) returns parser:ParsingError? {

        self.parserState = check new (lines);
        self.tagSchema = tagSchema;
        self.allowAnchorRedefinition = allowAnchorRedefinition;
        self.allowMapEntryRedefinition = allowMapEntryRedefinition;
    }
}

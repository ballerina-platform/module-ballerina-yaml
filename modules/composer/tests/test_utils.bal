import yaml.schema;

function obtainComposerState(string[] lines, map<schema:YAMLTypeConstructor> tagSchema = {},
    boolean allowAnchorRedefinition = true, boolean allowMapEntryRedefinition = false)
    returns ComposerState|ComposingError
    => check new (lines, tagSchema, allowAnchorRedefinition, allowMapEntryRedefinition);

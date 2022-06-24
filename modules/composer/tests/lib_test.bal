import ballerina/test;
import yaml.common;

@test:Config {
    dataProvider: nativeDataStructureDataGen,
    groups: ["composer"]
}
function testGenerateNativeDataStructure(string|string[] line, json structure) returns error? {
    ComposerState state = check obtainComposerState((line is string) ? [line] : line);
    json output = check composeDocument(state);

    test:assertEquals(output, structure);
}

function nativeDataStructureDataGen() returns map<[string|string[], json]> {
    return {
        "empty document": ["", ()],
        "empty sequence": ["[]", []],
        "mapping": ["{key: value}", {"key": "value"}],
        "multiple flow-mapping": ["{key1: value1, key2: value2}", {"key1": "value1", "key2": "value2"}],
        "multiple flow-sequence": ["[first, second]", ["first", "second"]],
        "block style nested mapping": [["key1: ", " key2: value"], {"key1": {"key2": "value"}}],
        "block style nested sequence": [["- ", " - first", " - second"], [["first", "second"]]],
        "mapping nested under sequence": [["- first: item1", "  second: item2", "- third: item3"], [{"first": "item1", "second": "item2"}, {"third": "item3"}]],
        "multiple mapping nested under sequence": [["- first:", "    second: item2", "- third: item3"], [{"first": {"second": "item2"}}, {"third": "item3"}]],
        "aliasing a string": [["- &anchor value", "- *anchor"], ["value", "value"]],
        "aliasing a sequence": [["- &anchor", " - first", " - second", "- *anchor"], [["first", "second"], ["first", "second"]]],
        "only explicit key in block mapping": ["?", {"": ()}],
        "explicit key and mapping value in block mapping": [["?", ":"], {"": ()}],
        "explicit key in block mapping": ["? key", {"key": ()}],
        "explicit key with mapping value in block mapping": [["? key", ":"], {"key": ()}],
        "explicit key empty key": [["? ", ": value"], {"": "value"}],
        "empty value flow mapping": ["{key,}", {"key": ()}],
        "empty values in block mapping": [["first:", "second:"], {"first": (), "second": ()}],
        // "empty key indented in block mapping": [["first:", "  : value"], {"first": {"": "value"}}],
        // "empty key at same indent in block mapping": [["key: first", ": second"], {"key": "first", "": "second"}],
        "anchoring the key after empty node": [["a: ", "&anchor b: *anchor"], {"a": (), "b": "b"}],
        "anchoring the key of nested value": [["a: ", "  &anchor b: *anchor"], {"a": {"b": "b"}}],
        "anchoring the empty node of a map": [["a: &anchor", "b: *anchor"], {"a": (), "b": ()}],
        "single flow implicit map": ["[key: value]", [{"key": "value"}]],
        "nested flow implicit map": ["[outer: {nested: value}]", [{"outer": {"nested": "value"}}]],
        "multiple flow implicit maps": [["[first: value1,", "second: value2]"], [{"first": "value1"}, {"second": "value2"}]]
    };
}

@test:Config {
    dataProvider: invalidEventTreeDataGen,
    groups: ["composer"]
}
function testComposeInvalidEventTree(string[] lines) returns error? {
    ComposerState state = check obtainComposerState(lines);

    json|error output = composeDocument(state);
    test:assertTrue(output is ComposingError);
}

function invalidEventTreeDataGen() returns map<[string[]]> {
    return {
        "multiple root data values": [["|-", " 123", "", "-", " 123"]],
        "flow style sequence without end": [["[", " first, ", "second "]],
        "aliasing anchor does note exist": [["*alias"]],
        "invalid explicit tags must return an error": [["!!int alias"]],
        "cyclic reference": [["- &anchor [*anchor]"]],
        "two block keys in same line": [["first: value1 second: value2"]],
        "not closing flow-style sequence": [["[1, 2"]],
        "not closing flow-style mapping": [["{a: b, c: d"]],
        "ending a sequence with }": [["[1, 2}"]],
        "ending a mapping with ]": [["{a: b, c: d]"]],
        "ending a sequence with document marker": [["[1, 2", "..."]],
        "ending a mapping with document marker": [["{a: b, c: d", "..."]],
        "mapping with sequence tag": [["!!seq {a: b}"]],
        "sequence with mapping tag": [["!!map [1, 2]"]],
        "scalar with sequence tag": [["!!str [1, 2]"]],
        "two consecutive directive documents": [["%YAML 1.2", "---", "%YAML 1.3", "---"]]
    };
}

@test:Config {
    dataProvider: streamDataGen,
    groups: ["composer"]
}
function testComposeMultipleDocuments(string[] lines, json[] expectedDocs) returns error? {
    ComposerState state = check obtainComposerState(lines);
    json[] docs = check composeStream(state);

    test:assertEquals(docs, expectedDocs);

}

function streamDataGen() returns map<[string[], json[]]> {
    return {
        "multiple bare documents": [["first doc", "...", "second doc"], ["first doc", "second doc"]],
        "explicit after bare": [["first doc", "---", "second doc"], ["first doc", "second doc"]],
        "explicit after directive": [["%YAML 1.1", "---", "first doc", "---", "second doc"], ["first doc", "second doc"]],
        "any explicit after directive": [["%YAML 1.1", "---", "first doc", "...", "---", "second doc"], ["first doc", "second doc"]],
        "explicit after empty directive": [["%YAML 1.1", "---", "# empty doc", "---", "second doc"], [(), "second doc"]],
        "directive after empty bare": [["# empty doc", "...", "%YAML 1.1", "---", "second doc", "..."], [(), "second doc"]],
        "two empty directive": [["---", "# empty doc", "---"], [(), ()]],
        "bare after directive": [["%YAML 1.1", "---", "first doc", "...", "second doc"], ["first doc", "second doc"]],
        "multiple end document markers": [["first doc", "...", "..."], ["first doc"]],
        "hoping out from block collection": [["-", " - value", "...", "second doc"], [[["value"]], "second doc"]]
    };
}

@test:Config {
    groups: ["composer"]
}
function testInvalidStartEventOfStream() returns error? {
    ComposerState state = check obtainComposerState([""]);
    json|error output = composeNode(state, {startType: common:STREAM});

    test:assertTrue(output is ComposeError);
}

@test:Config {
    groups: ["composer"]
}
function testRestrictRedefiningOfAliases() returns error? {
    ComposerState state = check obtainComposerState(["first: &anchor first", "second: &anchor second"], allowAnchorRedefinition = false);
    json|error output = composeDocument(state);

    test:assertTrue(output is common:AliasingError);
}

@test:Config {
    groups: ["composer"]
}
function testAllowRedefinitionOfMapEntires() returns error? {
    ComposerState state = check obtainComposerState(["key: first", "key: second"], allowMapEntryRedefinition = true);
    json output = check composeDocument(state);

    test:assertEquals(output.key, "second");
}

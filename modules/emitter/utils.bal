import yaml.schema;
import yaml.common;

# Obtain the topmost event from the event tree.
#
# + state - Current emitter state
# + return - The topmost event from the current tree.
function getEvent(EmitterState state) returns common:Event {
    if state.events.length() < 1 {
        return {endType: common:STREAM};
    }
    return state.events.shift();
}

# Reduce the long tag name to shorthand using the tag schema.
# Else, represent it fully via a verbatim tag.
#
# + tag - Tag to be reduced
# + return - Reduced tag
function reduceTagHandle(string? tag) returns string {
    // Returns an empty string if there is no tag.
    if tag == () {
        return "";
    }

    string[] keys = schema:defaultTagHandles.keys();

    // Check if the tag is reducible via the default tag schema.
    string tagHandleReference;
    foreach string key in keys {
        tagHandleReference = schema:defaultTagHandles.get(key);
        if tag.startsWith(tagHandleReference) {
            return key + tag.substring(tagHandleReference.length());
        }
    }

    // Represents the tag fully as a verbatim tag if not reducible.
    return string `!<${tag}>`;
}

# Write a single node into the YAML document.
#
# + state - Current state of the emitter
# + value - Value of the node to be written
# + tag - Tag of the node
# + tagAsSuffix - If set, the tag is written after the value
# + return - YAML string representing the node
function writeNode(EmitterState state, string? value, string? tag, boolean tagAsSuffix = false) returns string {
    if state.canonical {
        return tagAsSuffix ? value.toString() + " " + reduceTagHandle(tag)
            : reduceTagHandle(tag) + " " + value.toString();
    }
    return value.toString();
}

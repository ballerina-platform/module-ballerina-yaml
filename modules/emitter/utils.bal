import yaml.common;
import yaml.schema;

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

# Write a single node into the YAML document.
#
# + state - Current state of the emitter
# + value - Value of the node to be written
# + tag - Tag of the node
# + tagAsSuffix - If set, the tag is written after the value
# + return - YAML string representing the node
function writeNode(EmitterState state, string? value, string? tag, boolean tagAsSuffix = false) returns string {
    if tag == () {
        return value.toString();
    }

    // A tag with !! must be appended to the value only if the canonical flag is set
    if tag.startsWith(schema:defaultGlobalTagHandle) {
        return state.canonical ? appendTagToValue(tagAsSuffix,
            "!!" + tag.substring(schema:defaultGlobalTagHandle.length()), value) : value.toString();
    }

    // A tag with ! must be appended to the value in the original form
    if tag.startsWith(schema:defaultLocalTagHandle) {
        return appendTagToValue(tagAsSuffix, tag, value);
    }

    // Represents the tag fully as a verbatim tag if not reducible.
    string customTag = string `!<${tag}>`;

    // Check if the tag is reducible by the custom tag handless.
    foreach [string, string] tagEntry in state.customTagHandles.entries() {
        if tag.startsWith(tagEntry[1]) {
            customTag = tagEntry[0] + tag.substring(tagEntry[1].length());
            break;
        }
    }

    // Append the custom tags and add the tag handle as a directive
    return appendTagToValue(tagAsSuffix, customTag, value);
}

# Append the tag to the value either as a prefix or a suffix.
#
# + tagAsSuffix - If set, the tag is written after the value  
# + tag - Tag of the node  
# + value - Value of the node to be written
# + return - String with tag appended to the value
function appendTagToValue(boolean tagAsSuffix, string tag, string? value) returns string
    => tagAsSuffix ? value.toString() + " " + tag : tag + " " + value.toString();

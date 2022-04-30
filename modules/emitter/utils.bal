import yaml.schema;
import yaml.event;

# Obtain the topmost event from the event tree.
#
# + state - Current emitter state
# + return - The topmost event from the current tree.
function getEvent(EmitterState state) returns event:Event {
    if state.events.length() < 1 {
        return {endType: event:STREAM};
    }
    return state.events.shift();
}

function reduceTagHandle(string? tag) returns string {
    if tag == () {
        return "";
    }

    string[] keys = schema:defaultTagHandles.keys();

    string tagHandleReference;
    foreach string key in keys {
        tagHandleReference = schema:defaultTagHandles.get(key);
        if tag.startsWith(tagHandleReference) {
            return key + tag.substring(tagHandleReference.length());
        }
    }

    return string `!<${tag}>`;
}

function writeNode(EmitterState state, string? value, string? tag, boolean tagAsSuffix = false) returns string {
    if state.canonical {
        return tagAsSuffix ? value.toString() + " " + reduceTagHandle(tag)
            : reduceTagHandle(tag) + " " + value.toString();
    }
    return value.toString();
}

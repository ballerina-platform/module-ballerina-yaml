import ballerina/lang.array;
import yaml.common;

# Represents the variables of the Emitter state.
public class EmitterState {
    # YAML content of a document as an array of strings
    string[] document;
    string[] documentTags;

    # Custom tag handles that can be included in the directive document
    map<string> customTagHandles;

    # Total whitespace for a single indent
    readonly & string indent;

    # If set, the tag is written explicitly along with the value
    readonly & boolean canonical;

    private boolean lastBareDoc = false;

    # Event tree to be converted
    common:Event[] events;

    public function init(common:Event[] events, map<string> customTagHandles,
        int indentationPolicy, boolean canonical) {

        self.events = events;
        self.customTagHandles = customTagHandles;
        self.canonical = canonical;
        self.document = [];
        self.documentTags = [];

        // Setup the total whitespace for an indentation
        string indent = "";
        foreach int i in 1 ... indentationPolicy {
            indent += " ";
        }
        self.indent = indent;
    }

    function addLine(string line) => self.document.push(line);

    function addTagHandle(string tagHandle) {
        if self.documentTags.indexOf(tagHandle) == () {
            self.documentTags.push(tagHandle);
        }
    }

    function getDocument(boolean isStream = false) returns string[] {
        string[] output = self.document.clone();

        if self.documentTags.length() > 0 {
            output.unshift("---");
            self.documentTags.sort(array:DESCENDING).forEach(tagHandle =>
                output.unshift(string `%TAG ${tagHandle} ${self.customTagHandles.get(tagHandle)}`));
            if self.lastBareDoc {
                output.unshift("...");
                self.lastBareDoc = false;
            }
            output.push("...");
        } else if isStream && output.length() > 0 {
            output.unshift("---");
            self.lastBareDoc = true;
        }

        self.document = [];
        self.documentTags = [];

        return output;
    }
}

class Composer {
    Parser parser;
    private Event? buffer = ();
    private map<anydata> anchorBuffer = {};
    private boolean docTerminated = false;

    function init(Parser parser) {
        self.parser = parser;
    }

    function isEndOfDocument(Event event) returns boolean => event is EndEvent && (event.endType == STREAM || event.endType == DOCUMENT);

    public function composeDocument(Event? eventParam = ()) returns anydata|ParsingError|LexicalError|ComposingError {
        // Obtain the root event
        Event event = eventParam is () ? check self.checkEvent() : eventParam;

        // Return an empty document if end is reached
        if self.isEndOfDocument(event) {
            return ();
        }

        // TODO: Set up the hash map for tag handling
        if event is DocumentStartEvent {
            event = check self.checkEvent();
        }

        // Construct the single document
        anydata output = check self.composeNode(event);

        // Return an error if there is another root event
        event = check self.checkEvent();
        return self.isEndOfDocument(event) ? output
            : self.generateError("There can only be one root event to a document");
    }

    public function composeStream() returns anydata[]|ParsingError|LexicalError|ComposingError {
        anydata[] output = [];
        Event event = check self.checkEvent();

        while !(event is EndEvent && event.endType == STREAM) {
            output.push(check self.composeDocument(event));
            self.docTerminated = false;
            event = check self.checkEvent();
        }

        return output;
    }

    private function composeSequence(boolean flowStyle) returns anydata[]|LexicalError|ParsingError|ComposingError {
        anydata[] sequence = [];
        Event event = check self.checkEvent();

        while true {
            if event is EndEvent {
                match event.endType {
                    MAPPING => {
                        return self.generateError("Expected a sequence end event");
                    }
                    SEQUENCE => {
                        break;
                    }
                    DOCUMENT|STREAM => {
                        self.docTerminated = event.endType == DOCUMENT;
                        if !flowStyle {
                            break;
                        }
                        return self.generateError("Expected a sequence end event");
                    }
                }
            }

            if event is DocumentStartEvent {
                if !flowStyle {
                    break;
                }
                return self.generateError("Expected a sequence end event");
            }

            sequence.push(check self.composeNode(event));
            event = check self.checkEvent();
        }

        return sequence;
    }

    private function composeMapping(boolean flowStyle) returns map<anydata>|LexicalError|ParsingError|ComposingError {
        map<anydata> structure = {};
        Event event = check self.checkEvent(EXPECT_KEY);

        while true {
            if event is EndEvent {
                match event.endType {
                    MAPPING => {
                        break;
                    }
                    SEQUENCE => {
                        return self.generateError("Expected a mapping end event");
                    }
                    DOCUMENT|STREAM => {
                        self.docTerminated = event.endType == DOCUMENT;
                        if !flowStyle {
                            break;
                        }
                        return self.generateError("Expected a mapping end event");
                    }
                }
            }

            if event is DocumentStartEvent {
                if !flowStyle {
                    break;
                }
                return self.generateError("Expected a sequence end event");
            }

            if !(event is StartEvent|ScalarEvent) {
                return self.generateError("Expected a key for a mapping");
            }

            anydata key = check self.composeNode(event);
            event = check self.checkEvent(EXPECT_VALUE);
            anydata value = check self.composeNode(event);

            structure[key.toString()] = value;
            event = check self.checkEvent(EXPECT_KEY);
        }

        return structure;
    }

    // TODO: Tag resolution for 
    // private function composeScalar() returns anydata|LexicalError|ParsingError|ComposingError {
    //     Event event = check self.checkEvent();

    // }

    private function composeNode(Event event) returns anydata|LexicalError|ParsingError|ComposingError {
        anydata output;

        // Check for +SEQ
        if event is StartEvent && event.startType == SEQUENCE {
            output = check self.composeSequence(event.flowStyle);
            check self.checkAnchor(event, output);
            return output;
        }

        // Check for +MAP
        if event is StartEvent && event.startType == MAPPING {
            output = check self.composeMapping(event.flowStyle);
            check self.checkAnchor(event, output);
            return output;
        }

        // Check for aliases
        if event is AliasEvent {
            return self.anchorBuffer.hasKey(event.alias)
                ? self.anchorBuffer[event.alias]
                : self.generateError(string `The anchor '${event.alias}' does not exist`);
        }

        // Check for SCALAR
        if event is ScalarEvent {
            output = event.value;
            check self.checkAnchor(event, output);
            return output;
        }
    }

    private function checkAnchor(StartEvent|ScalarEvent event, anydata assignedValue) returns ComposingError? {
        if event.anchor != () {
            if self.anchorBuffer.hasKey(<string>event.anchor) {
                return self.generateError(string `Duplicate anchor definition of '${<string>event.anchor}'`);
            }
            self.anchorBuffer[<string>event.anchor] = assignedValue;
        }
    }

    private function checkEvent(ParserOption option = DEFAULT, DocumentType docType = BARE_DOCUMENT) returns Event|LexicalError|ParsingError {
        if self.docTerminated {
            return {endType: DOCUMENT};
        }
        return self.parser.parse(option, docType);
    }

    # Generates a Parsing Error Error.
    #
    # + message - Error message
    # + return - Constructed Parsing Error message  
    private function generateError(string message) returns ComposingError {
        string text = "Composing Error at line "
                        + (self.parser.lexer.lineNumber + 1).toString()
                        + " index "
                        + self.parser.lexer.index.toString()
                        + ": "
                        + message
                        + ".";
        return error ComposingError(text);
    }
}

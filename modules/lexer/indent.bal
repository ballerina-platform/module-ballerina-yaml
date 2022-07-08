import yaml.common;

# Represents an indent of a block collection
#
# + index - Index of the start of the collection character
# + collection - Collection with that indent
type Indent record {|
    int index;
    common:Collection collection;
|};

# Validates the indentation of block collections.
# Increments and decrement the indentation safely.
# If the indent is explicitly given, then the function continues for mappings.
#
# + state - Current lexer state  
# + mapIndex - If the current token is a mapping key, then the starting index of it.
# + return - Change of indentation. Else, an indentation error on failure
function checkIndent(LexerState state, int? mapIndex = ()) returns Indentation|LexicalError {
    int startIndex = mapIndex == () ? state.index - 1 : mapIndex;
    if mapIndex != () {
        state.keyDefinedForLine = true;
    }

    if isTabInIndent(state, startIndex) {
        return generateIndentationError(state, "Cannot have tab as an indentation");
    }

    common:Collection collection = mapIndex == () ? common:SEQUENCE : common:MAPPING;

    if state.indent == startIndex {
        common:Collection[] existingIndentType = from Indent indent in state.indents
            where indent.index == startIndex
            select indent.collection;

        // The current token is a mapping key and a sequence entry exists for the indent
        if mapIndex is int && existingIndentType.indexOf(<common:Collection>common:SEQUENCE) is int {
            if existingIndentType.indexOf(<common:Collection>common:MAPPING) is int {
                return generateIndentationRecord(state, -1, [state.indents.pop().collection]);
            } else {
                return generateIndentationError(state, "Block mapping cannot have the same indent as a block sequence");
            }
        }

        // The current token is a sequence entry and a mapping key exists for the indent
        if mapIndex is () && existingIndentType.indexOf(<common:Collection>common:MAPPING) is int {
            if existingIndentType.indexOf(<common:Collection>common:SEQUENCE) is int {
                return generateIndentationRecord(state, 0, []);
            } else {
                state.indents.push({index: startIndex, collection: common:SEQUENCE});
                return generateIndentationRecord(state, 1, [common:SEQUENCE]);
            }
        }
        return generateIndentationRecord(state, 0, []);
    }

    if state.indent < startIndex {
        state.indents.push({index: startIndex, collection});
        state.indent = startIndex;
        return generateIndentationRecord(state, 1, [collection]);
    }

    Indent? removedIndent = ();
    common:Collection[] returnCollection = [];
    while state.indent > startIndex && state.indents.length() > 0 {
        removedIndent = state.indents.pop();
        state.indent = (<Indent>removedIndent).index;
        returnCollection.push((<Indent>removedIndent).collection);
    }

    if state.indents.length() > 0 && removedIndent is Indent {
        Indent removedSecondIndent = state.indents.pop();
        if removedSecondIndent.index == startIndex && collection == common:MAPPING {
            returnCollection.push(removedIndent.collection);
            removedIndent = removedSecondIndent;
        } else {
            state.indents.push(removedSecondIndent);
        }
    }

    if state.indent == startIndex {
        state.indents.push({index: state.indent, collection});
        if returnCollection.length() > 1 {
            _ = returnCollection.pop();
            return generateIndentationRecord(state, -1, returnCollection);
        }
    }

    return generateIndentationError(state, "Invalid indentation");
}

# Differentiate the planar and anchor keys against the key of a mapping.
#
# + state - Current lexer state
# + outputToken - Planar or anchor key
# + process - Function to scan the lexeme
# + return - Returns the tokenized state with correct YAML token
function checkMappingValueIndent(LexerState state, YAMLToken outputToken,
    (function (LexerState state) returns boolean|LexicalError)? process = ()) returns LexerState|LexicalError {

    state.indentationBreak = false;
    boolean enforceMapping = state.enforceMapping;
    state.enforceMapping = false;

    LexerState token;
    boolean notSufficientIndent;
    if process == () { // If the token is scanned, just produce the output
        token = state.tokenize(outputToken);
        notSufficientIndent = state.index < state.indentStartIndex;
    } else {
        notSufficientIndent = assertIndent(state, 1) is LexicalError;
        state.updateStartIndex();
        token = check iterate(state, process, outputToken);
    }

    if state.isFlowCollection() {
        return token;
    }

    // Ignore whitespace until a character is found
    int numWhitespace = 0;
    while isWhitespace(state) {
        numWhitespace += 1;
        state.forward();
    }

    if notSufficientIndent { // Not sufficient indent to process as a value token
        if state.peek() == ":" && !state.isFlowCollection() { // The token is a mapping key
            token.indentation = check checkIndent(state, state.indentStartIndex);
            return token;
        }
        return generateIndentationError(state, "Insufficient indentation for a scalar");
    }
    if state.peek() == ":" && !state.isFlowCollection() {
        token.indentation = check checkIndent(state, state.indentStartIndex);
        return token;
    }
    state.forward(-numWhitespace);
    return enforceMapping ? generateIndentationError(state, "Insufficient indentation for a scalar") : token;
}

# Check if the current index has sufficient indent.
#
# + state - Current lexer state  
# + offset - Additional whitespace after the parent indent  
# + captureIndentationBreak - Flag is set if the token is allowed as prefix to a mapping key name
# + return - An error if the indent is not sufficient
function assertIndent(LexerState state, int offset = 0, boolean captureIndentationBreak = false) returns LexicalError? {
    if state.index < state.indent + offset {
        if captureIndentationBreak {
            state.indentationBreak = true;
            return;
        }
        return generateIndentationError(state, "Invalid indentation");
    }
}

function generateIndentationRecord(LexerState state, IndentChange change, common:Collection[] collection)
    returns Indentation => {change, collection, tokens: state.tokensForMappingValue.clone()};

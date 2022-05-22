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

    common:Collection collection = mapIndex == () ? common:SEQUENCE : common:MAPPING;

    if state.indent == startIndex {
        common:Collection[] existingIndentType = from Indent indent in state.indents
            where indent.index == startIndex
            select indent.collection;

        // The current token is a mapping key and a sequence entry exists for the indent
        if mapIndex is int && existingIndentType.indexOf(<common:Collection>common:SEQUENCE) is int {
            if existingIndentType.indexOf(<common:Collection>common:MAPPING) is int {
                return {
                    change: -1,
                    collection: [state.indents.pop().collection]
                };
            } else {
                return generateIndentationError(state, "Block mapping cannot have the same indent as a block sequence");
            }
        }

        // The current token is a sequence entry and a mapping key exists for the indent
        if mapIndex is () && existingIndentType.indexOf(<common:Collection>common:MAPPING) is int {
            if existingIndentType.indexOf(<common:Collection>common:SEQUENCE) is int {
                return {
                    change: 0,
                    collection: []
                };
            } else {
                state.indents.push({index: startIndex, collection: common:SEQUENCE});
                return {
                    change: 1,
                    collection: [common:SEQUENCE]
                };
            }
        }

        return {
            change: 0,
            collection: []
        };
    }

    if state.indent < startIndex {
        state.indents.push({index: startIndex, collection});
        state.indent = startIndex;
        return {
            change: 1,
            collection: [collection]
        };
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
            return {
                change: -1,
                collection: returnCollection
            };
        }
    }

    return generateIndentationError(state, "Invalid indentation");
}

# Check if the current index has sufficient indent.
#
# + state - Current lexer state
# + offset - Additional whitespace after the parent indent
# + return - An error if the indent is not sufficient
function assertIndent(LexerState state, int offset = 0) returns LexicalError? {
    if state.index < state.indent + offset {
        return generateIndentationError(state, "Invalid indentation");
    }
}

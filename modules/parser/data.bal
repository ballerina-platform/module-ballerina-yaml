import yaml.lexer;
import yaml.common;

type TagStructure record {|
    string? anchor = ();
    string? tag = ();
|};

# Merge tag structure with the respective data.
#
# + state - Current parser state  
# + option - Selected parser option  
# + tagStructure - Constructed tag structure if exists  
# + peeked - If the expected token is already in the state  
# + definedProperties - Tag properties defined by the previous node
# + return - The constructed scalar or start event on success.
function appendData(ParserState state, ParserOption option,
    TagStructure tagStructure = {}, boolean peeked = false, TagStructure? definedProperties = ())
    returns common:Event|ParsingError {

    state.blockSequenceState = VALUE;
    common:Event? buffer = ();

    // Check for nested explicit keys
    if !peeked {
        check checkToken(state, peek = true);
        if state.tokenBuffer.token == lexer:MAPPING_KEY {
            state.explicitKey = true;
            check checkToken(state);
        }

    }
    boolean explicitKey = state.explicitKey;

    if option == EXPECT_VALUE && state.currentToken.token == lexer:MAPPING_KEY {
        buffer = {value: ()};
    }

    lexer:Indentation? indentation = ();
    if state.explicitKey {
        indentation = state.currentToken.indentation;
        check separate(state, true);
    }

    state.updateLexerContext(state.explicitKey ? lexer:LEXER_EXPLICIT_KEY : lexer:LEXER_START);

    map<json> contentValue = check content(state, peeked, option, state.explicitKey, tagStructure);
    boolean isAlias = contentValue.hasKey("alias");

    state.explicitKey = false;
    if !explicitKey {
        indentation = state.currentToken.indentation;
    }

    // Check if the current node is a key
    boolean isJsonKey = state.lexerState.isJsonKey;

    // Ignore the whitespace and lines if there is any
    check separate(state, true);
    check checkToken(state, peek = true);

    // Check if the next token is a mapping value or    
    if state.tokenBuffer.token == lexer:MAPPING_VALUE || state.tokenBuffer.token == lexer:SEPARATOR {
        check checkToken(state);
    }

    // If there are no whitespace, and the current token is ':'
    state.lexerState.isJsonKey = false;
    if state.currentToken.token == lexer:MAPPING_VALUE {
        if state.lastKeyLine == state.lineIndex && !state.lexerState.isFlowCollection() {
            return generateGrammarError(state, "Two block mapping keys cannot be defined in the same line");
        }
        if explicitKey {
            state.lastExplicitKeyLine = state.lineIndex;
        }
        state.lastKeyLine = state.lineIndex;

        if state.explicitDoc {
            return generateGrammarError(state,
                string `'${lexer:PLANAR_CHAR}' token cannot start in the same line as the directive marker`);
        }

        check separate(state, isJsonKey || state.lexerState.isFlowCollection(), true);
        if option == EXPECT_VALUE {
            buffer = {value: ()};
        }
    } else {
        // There is already tag properties defined adn the value is not a key
        if definedProperties is TagStructure {
            if definedProperties.anchor != () && tagStructure.anchor != () {
                return generateGrammarError(state, "Only one anchor is allowed for a node");
            }
            if definedProperties.tag != () && tagStructure.tag != () {
                return generateGrammarError(state, "Only one tag is allowed for a node");
            }
        }
    }

    // If there are no whitespace, and the current token is ","
    if state.currentToken.token == lexer:SEPARATOR {
        check separate(state, true);
        if option == EXPECT_KEY {
            state.eventBuffer.push({value: ()});
        }
    }

    if indentation is lexer:Indentation {
        match indentation.change {
            1 => { // Increased
                // Block sequence
                if contentValue.hasKey("startType") && contentValue.startType == common:SEQUENCE {
                    return constructEvent(state, {startType: indentation.collection.pop()}, tagStructure);
                }

                // Block mapping
                return differentiateTagProperty(state, indentation.tokens,
                    {startType: indentation.collection.pop()}, contentValue, tagStructure, isAlias);
            }
            -1 => { // Decreased 
                buffer = {endType: indentation.collection.shift()};
                foreach common:Collection collectionItem in indentation.collection {
                    state.eventBuffer.push({endType: collectionItem});
                }
            }
        }
    }
    if isAlias && (tagStructure.anchor != () || tagStructure.tag != ()) {
        return generateGrammarError(state, "An alias node cannot have tag properties");
    }
    common:Event event = check constructEvent(state, contentValue, isAlias ? () : tagStructure);

    if buffer == () {
        return event;
    }
    state.eventBuffer.push(event);
    return buffer;
}

function differentiateTagProperty(ParserState state, lexer:YAMLToken[] tokens, map<json> currentValue,
    map<json> contentValue, TagStructure tagStructure, boolean isAlias) returns common:Event|ParsingError {
    match tokens.length() {
        0 => { // The tag structure belongs to the empty node
            state.eventBuffer.push(check constructEvent(state, contentValue));
            return constructEvent(state, currentValue, tagStructure);
        }
        1 => { // The tag structure is divided between the key and the empty node
            match tokens.pop() {
                lexer:ANCHOR => {
                    if isAlias && tagStructure.tag != () {
                        return generateGrammarError(state, "An alias node cannot have tag properties");
                    }
                    state.eventBuffer.push(check constructEvent(state, contentValue, isAlias ? () : {anchor: tagStructure.anchor}));
                    return constructEvent(state, {tag: tagStructure.tag}, currentValue);
                }
                lexer:TAG => {
                    if isAlias && tagStructure.anchor != () {
                        return generateGrammarError(state, "An alias node cannot have tag properties");
                    }
                    state.eventBuffer.push(check constructEvent(state, contentValue, isAlias ? () : {tag: tagStructure.tag}));
                    return constructEvent(state, {anchor: tagStructure.anchor}, currentValue);
                }
            }
        }
        2 => { // The whole tag structure belongs mapping key
            if isAlias && (tagStructure.anchor != () || tagStructure.tag != ()) {
                return generateGrammarError(state, "An alias node cannot have tag properties");
            }
            state.eventBuffer.push(check constructEvent(state, contentValue, isAlias ? () : tagStructure));
            return constructEvent(state, currentValue);
        }
    }
    return generateGrammarError(state,
        string `There cannot be more than 2 tag properties to a node, but found ${tokens.length()}`);
}

# Extracts the data for the given node.
#
# + state - Current parser state  
# + peeked - If the expected token is already in the state  
# + option - Expected values inside a mapping collection  
# + explicitKey - Whether the current node is an explicit key
# + tagStructure - Tag structure of the current node
# + return - String if a scalar event. The respective collection if a start event. Else, returns an error.
function content(ParserState state, boolean peeked, ParserOption option, boolean explicitKey,
    TagStructure tagStructure = {}) returns map<json>|ParsingError {

    if !peeked {
        check checkToken(state);
    }

    match state.currentToken.token {
        lexer:SEPARATOR|lexer:MAPPING_VALUE => {
            return {value: ""};
        }
        lexer:EOL => {
            return {value: ""};
        }
    }

    if state.lastKeyLine == state.lineIndex && !state.lexerState.isFlowCollection() && option == EXPECT_KEY {
        return generateGrammarError(state, "Cannot have a scalar next to a block key-value pair");
    }

    // Check for flow and block nodes
    match state.currentToken.token {
        lexer:SINGLE_QUOTE_DELIMITER => {
            state.lexerState.isJsonKey = true;
            return {value: check singleQuoteScalar(state)};
        }
        lexer:DOUBLE_QUOTE_DELIMITER => {
            state.lexerState.isJsonKey = true;
            return {value: check doubleQuoteScalar(state)};
        }
        lexer:PLANAR_CHAR => {
            return {value: check planarScalar(state)};
        }
        lexer:SEQUENCE_START|lexer:SEQUENCE_ENTRY => {
            return {startType: common:SEQUENCE};
        }
        lexer:MAPPING_START => {
            return {startType: common:MAPPING};
        }
        lexer:LITERAL|lexer:FOLDED => {
            if state.lexerState.isFlowCollection() {
                return generateGrammarError(state, "Cannot have a block node inside a flow node");
            }
            return {value: check blockScalar(state, state.currentToken.token == lexer:FOLDED)};
        }
        lexer:ALIAS => {
            return {alias: state.currentToken.value};
        }
        lexer:ANCHOR|lexer:TAG|lexer:TAG_HANDLE => {
            common:Event event = check nodeComplete(state, EXPECT_KEY, tagStructure);
            if explicitKey {
                return event;
            }
            if event is common:StartEvent && event.startType == common:MAPPING {
                return {startType: common:MAPPING};
            }
            if event is common:ScalarEvent {
                state.eventBuffer.push(event);
                return {value: ""};
            }
        }
    }

    // Check for empty nodes with explicit keys
    if state.explicitKey {
        match state.currentToken.token {
            lexer:MAPPING_VALUE => {
                return {value: ""};
            }
            lexer:SEPARATOR => {
                state.eventBuffer.push({value: ()});
                return {value: ""};
            }
            lexer:MAPPING_END => {
                state.eventBuffer.push({value: ()});
                state.eventBuffer.push({endType: common:MAPPING});
                return {value: ""};
            }
            lexer:EOL => { // Only the mapping key
                state.eventBuffer.push({value: ()});
                return {value: ""};
            }
        }
    }

    return generateExpectError(state, "<data-node>", state.prevToken);
}

# Verifies the grammar production for separation between nodes.
#
# + state - Current parser state  
# + optional - If the separation is optional  
# + allowEmptyNode - If it is possible to have an empty node.
# + return - An error on invalid separation.
function separate(ParserState state, boolean optional = false, boolean allowEmptyNode = false) returns ()|ParsingError {
    state.updateLexerContext(lexer:LEXER_START);
    check checkToken(state, peek = true);

    // If separate is optional, skip the check when either lexer:EOL or separate-in-line is not detected.
    if optional && !(state.tokenBuffer.token == lexer:EOL || state.tokenBuffer.token == lexer:SEPARATION_IN_LINE) {
        return;
    }

    // Consider the separate for the latter contexts
    check checkToken(state);

    if state.currentToken.token == lexer:SEPARATION_IN_LINE {
        // Check for s-b comment
        check checkToken(state, peek = true);
        if state.tokenBuffer.token != lexer:EOL {
            return;
        }
        check checkToken(state);
    }

    // For the rest of the contexts, check either separation in line or comment lines
    while state.currentToken.token == lexer:EOL || state.currentToken.token == lexer:EMPTY_LINE {
        ParsingError? err = state.initLexer();
        if err is ParsingError {
            return optional || allowEmptyNode ? () : err;
        }
        check checkToken(state, peek = true);

        //TODO: account flow-line prefix
        match state.tokenBuffer.token {
            lexer:EOL|lexer:EMPTY_LINE => { // Check for multi-lines
                check checkToken(state);
            }
            lexer:SEPARATION_IN_LINE => { // Check for l-comment
                check checkToken(state);
                check checkToken(state, peek = true);
                if state.tokenBuffer.token != lexer:EOL {
                    return;
                }
                check checkToken(state);
            }
            _ => {
                return;
            }
        }
    }

    return generateExpectError(state, [lexer:EOL, lexer:SEPARATION_IN_LINE], state.currentToken.token);
}

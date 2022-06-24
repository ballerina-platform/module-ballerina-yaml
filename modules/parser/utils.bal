import yaml.lexer;
import yaml.common;
import yaml.schema;

# Generates an event my combining to map<json> objects.
#
# + state - Current parser state
# + m1 - The first map structure
# + m2 - The second map structure
# + return - The constructed event after combined.
function constructEvent(ParserState state, map<json> m1, map<json>? m2 = ()) returns common:Event|ParsingError {
    map<json> returnMap = m1.clone();

    if m2 != () {
        m2.keys().forEach(function(string key) {
            returnMap[key] = m2[key];
        });
    }

    error|common:Event processedMap = returnMap.cloneWithType(common:Event);

    return processedMap is common:Event ? processedMap : common:generateConversionError('error:message(processedMap));
}

# Trims the trailing whitespace of a string.
#
# + value - String to be trimmed  
# + lastEscapedChar - Last escaped whitespace to be preserved
# + return - Trimmed string
function trimTailWhitespace(string value, int? lastEscapedChar = ()) returns string {
    int i = value.length() - 1;

    if i < 0 {
        return "";
    }

    while value[i] == " " || value[i] == "\t" {
        if i < 1 || (lastEscapedChar is int && i == lastEscapedChar) {
            break;
        }
        i -= 1;
    }

    return value.substring(0, i + 1);
}

# Assert the next lexer token with the predicted token.
# If no token is provided, then the next token is retrieved without an error checking.
# Hence, the error checking must be done explicitly.
#
# + state - Current parser state  
# + expectedTokens - Predicted token or tokens  
# + peek - Stores the token in the buffer
# + return - Parsing error if not found
function checkToken(ParserState state, lexer:YAMLToken|lexer:YAMLToken[] expectedTokens = lexer:DUMMY, boolean peek = false) returns (ParsingError)? {
    lexer:Token token;

    // Obtain a token form the lexer if there is none in the buffer.
    if state.tokenBuffer.token == lexer:DUMMY {
        state.prevToken = state.currentToken.token;
        state.lexerState = check lexer:scan(state.lexerState);
        token = state.lexerState.getToken();
    } else {
        token = state.tokenBuffer;
        state.tokenBuffer = {token: lexer:DUMMY};
    }

    // Add the token to the tokenBuffer if the peek flag is set.
    if peek {
        state.tokenBuffer = token;
    } else {
        state.currentToken = token;
    }

    // Bypass error handling.
    if expectedTokens == lexer:DUMMY {
        return;
    }

    // Generate a template error message if the expected token differ from the actual token.
    if (expectedTokens is lexer:YAMLToken && token.token != expectedTokens) ||
        (expectedTokens is lexer:YAMLToken[] && expectedTokens.indexOf(token.token) == ()) {
        return generateExpectError(state, expectedTokens, state.prevToken);
    }
}

# Check if the given key adheres to either a explicit or a implicit key.
#
# + state - Current parser state  
# + isSingleLine - If the scalar only spanned for one line.
# + return - An error on invalid key.
function verifyKey(ParserState state, boolean isSingleLine) returns ParsingError|() {
    // Explicit keys can span multiple lines. 
    if state.explicitKey {
        return;
    }

    // Regular keys can only exist within one line
    state.updateLexerContext(lexer:LEXER_START);
    check checkToken(state, peek = true);
    if state.tokenBuffer.token == lexer:MAPPING_VALUE && !isSingleLine {
        return generateGrammarError(state, "Mapping keys cannot span multiple lines");
    }
}

# Convert the shorthand tag to the complete tag by mapping the tag handle.
#
# + state - Current parser state
# + tagHandle - Tag handle of the event  
# + tagPrefix - Tag prefix of the event
# + return - The complete tag name of the event
function generateCompleteTagName(ParserState state, string tagHandle, string tagPrefix) returns string|ParsingError {
    string tagHandleName;

    // Check if the tag handle is defined in the custom tags.
    if state.customTagHandles.hasKey(tagHandle) {
        tagHandleName = state.customTagHandles.get(tagHandle);
    } else { // Else, check if the tag handle is in the default tags.
        if schema:defaultTagHandles.hasKey(tagHandle) {
            tagHandleName = schema:defaultTagHandles.get(tagHandle);
        }
        else {
            return generateAliasingError(state, string `'${tagHandle}' tag handle is not defined`);
        }
    }

    return tagHandleName + tagPrefix;
}

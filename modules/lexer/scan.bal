# Scan lexemes for the escaped characters.
# Adds the processed escaped character to the lexeme.
#
# + state - Current lexer state
# + return - An error on failure
function scanEscapedCharacter(LexerState state) returns LexicalError? {
    string currentChar;

    // Process double escape character
    if state.peek() == () {
        state.lexeme += "\\";
        return;
    } else {
        currentChar = <string>state.peek();
    }

    // Check for predefined escape characters
    if escapedCharMap.hasKey(currentChar) {
        state.lexeme += <string>escapedCharMap[currentChar];
        return;
    }

    // Check for unicode characters
    match currentChar {
        "x" => {
            check scanUnicodeEscapedCharacters(state, "x", 2);
            return;
        }
        "u" => {
            check scanUnicodeEscapedCharacters(state, "u", 4);
            return;
        }
        "U" => {
            check scanUnicodeEscapedCharacters(state, "U", 8);
            return;
        }
    }
    return generateInvalidCharacterError(state, "escaped character");
}

# Process the hex codes under the unicode escaped character.
#
# + state - Current lexer state
# + escapedChar - Escaped character before the digits. Only used to present in the error message.
# + length - Number of digits
# + return - An error on failure
function scanUnicodeEscapedCharacters(LexerState state, string escapedChar, int length) returns LexicalError? {

    // Check if the required digits do not overflow the current line.
    if state.line.length() <= length + state.index {
        return generateScanningError(state, "Expected " + length.toString() + " characters for the '\\" + escapedChar + "' unicode escape");
    }

    string unicodeDigits = "";

    // Check if the digits adhere to the hexadecimal code pattern.
    foreach int i in 0 ... length - 1 {
        state.forward();
        if matchRegexPattern(state, HEXADECIMAL_DIGIT_PATTERN) {
            unicodeDigits += <string>state.peek();
            continue;
        }
        return generateInvalidCharacterError(state, "unicode hex escape");
    }

    // Check if the lexeme can be converted to hexadecimal
    int|error hexResult = 'int:fromHexString(unicodeDigits);
    if hexResult is error {
        return generateScanningError(state, 'error:message(hexResult));
    }

    // Check if there exists a unicode string for the hexadecimal value
    string|error unicodeResult = 'string:fromCodePointInt(hexResult);
    if unicodeResult is error {
        return generateScanningError(state, 'error:message(unicodeResult));
    }

    state.lexeme += unicodeResult;
}

# Process double quoted scalar values.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token. An error on failure.
function scanDoubleQuoteChar(LexerState state) returns boolean|LexicalError {
    // Process nb-json characters
    if matchRegexPattern(state, JSON_PATTERN, exclusionPatterns = ["\\\\", "\""]) {
        state.lexeme += <string>state.peek();
        return false;
    }

    // Process escaped characters
    if state.peek() == "\\" {
        state.forward();
        check scanEscapedCharacter(state);
        state.lastEscapedChar = state.lexeme.length() - 1;
        return false;
    }

    // Terminate when delimiter is found
    if state.peek() == "\"" {
        return true;
    }

    return generateInvalidCharacterError(state, DOUBLE_QUOTE_CHAR);
}

# Process double quoted scalar values.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token. An error on failure.
function scanSingleQuotedChar(LexerState state) returns boolean|LexicalError {
    // Process nb-json characters
    if matchRegexPattern(state, JSON_PATTERN, exclusionPatterns = ["'"]) {
        state.lexeme += <string>state.peek();
        return false;
    }

    // Terminate when the delimiter is found
    if state.peek() == "'" {
        if state.peek(1) == "'" {
            state.lexeme += "'";
            state.forward();
            return false;
        }
        return true;
    }

    return generateInvalidCharacterError(state, SINGLE_QUOTE_CHAR);
}

# Process planar scalar values.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token. An error on failure.
function scanPlanarChar(LexerState state) returns boolean|LexicalError {
    // Store the whitespace before a ns-planar char
    string whitespace = "";
    int numWhitespace = 0;
    while state.peek() == "\t" || state.peek() == " " {
        whitespace += <string>state.peek();
        numWhitespace += 1;
        state.forward();
    }

    // Step back from the white spaces if EOL or ':' is reached 
    if state.peek() == () {
        state.forward(-numWhitespace);
        return true;
    }

    // Terminate when the flow indicators are detected inside flow style collections
    if matchRegexPattern(state, [FLOW_INDICATOR_PATTERN]) && state.isFlowCollection() {
        return true;
    }

    // Process ns-plain-safe character
    if matchRegexPattern(state, [PRINTABLE_PATTERN], [LINE_BREAK_PATTERN, BOM_PATTERN, WHITESPACE_PATTERN, "#", ":"]) {
        state.lexeme += whitespace + <string>state.peek();
        return false;
    }

    // Check for comments with a space before it
    if state.peek() == "#" {
        if state.peek(-1) == " " || state.peek(-1) == "\t" {
            state.forward(-numWhitespace);
            return true;
        }
        state.lexeme += whitespace + "#";
        return false;
    }

    // Check for mapping value with a space after it 
    if state.peek() == ":" {
        if !matchRegexPattern(state, [PRINTABLE_PATTERN], [LINE_BREAK_PATTERN, BOM_PATTERN, WHITESPACE_PATTERN], 1) {
            state.forward(-numWhitespace);
            return true;
        }
        state.lexeme += whitespace + ":";
        return false;
    }

    // If the whitespace is at the trail, discard it from the planar chars
    if numWhitespace > 0 {
        state.forward(-numWhitespace);
        return true;
    }

    if checkCharacter(state, ["}", "]"]) {
        return true;
    }

    return generateInvalidCharacterError(state, PLANAR_CHAR);
}

# Process block scalar values.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token. An error on failure.
function scanPrintableChar(LexerState state) returns boolean|LexicalError {
    if matchRegexPattern(state, PRINTABLE_PATTERN, [BOM_PATTERN, LINE_BREAK_PATTERN]) {
        state.lexeme += <string>state.peek();
        return false;
    }

    return true;
}

# Scan the lexeme for tag characters.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token. An error on failure.
function scanTagCharacter(LexerState state) returns boolean|LexicalError {
    // Check for URI character
    if matchRegexPattern(state, [URI_CHAR_PATTERN, WORD_PATTERN], ["!", FLOW_INDICATOR_PATTERN]) {
        state.lexeme += <string>state.peek();
        return false;
    }

    if matchRegexPattern(state, WHITESPACE_PATTERN) {
        return true;
    }

    // Process the hexadecimal values after '%'
    if state.peek() == "%" {
        check scanUnicodeEscapedCharacters(state, "%", 2);
        return false;
    }

    // Check for separator in flow style collections.
    if state.peek() == "," {
        return true;
    }

    return generateInvalidCharacterError(state, TAG);
}

# Scan the lexeme for URI characters
#
# + isVerbatim - If set, terminates when ">" is detected.
# + return - Generates a function to scan the URI characters.
function scanURICharacter(boolean isVerbatim = false) returns function (LexerState state) returns boolean|LexicalError {
    return function(LexerState state) returns boolean|LexicalError {
        // Check for URI characters
        if matchRegexPattern(state, [URI_CHAR_PATTERN, WORD_PATTERN]) {
            state.lexeme += <string>state.peek();
            return false;
        }

        // Process the hexadecimal values after '%'
        if state.peek() == "%" {
            check scanUnicodeEscapedCharacters(state, "%", 2);
            return false;
        }

        // Ignore the comments
        if matchRegexPattern(state, [LINE_BREAK_PATTERN, WHITESPACE_PATTERN]) {
            return true;
        }

        // Terminate when '>' is detected for a verbatim tag
        if isVerbatim && state.peek() == ">" {
            return true;
        }

        return generateInvalidCharacterError(state, "URI character");
    };
}

# Scan the lexeme for named tag handle.
#
# + differentiate - If set, the function handles to differentiate between named and primary tags.
# + return - Generates a function to scan the lexeme of a named or primary tag handle.
function scanTagHandle(boolean differentiate = false) returns function (LexerState state) returns boolean|LexicalError {
    return function(LexerState state) returns boolean|LexicalError {
        // Scan the word of the name tag.
        if matchRegexPattern(state, WORD_PATTERN) {
            state.lexeme += <string>state.peek();
            // Store the complete primary tag if another '!' cannot be detected.
            if differentiate && state.peek(1) == () {
                state.lexemeBuffer = state.lexeme.substring(1);
                state.lexeme = "!";
                return true;
            }
            return false;
        }

        // Scan the end delimiter of the tag.
        if state.peek() == "!" {
            state.lexeme += "!";
            return true;
        }

        // If the tag handle contains non-word character before '!', 
        // Then the tag is primary
        if differentiate && matchRegexPattern(state, [URI_CHAR_PATTERN, WORD_PATTERN], FLOW_INDICATOR_PATTERN) {
            state.lexemeBuffer = state.lexeme.substring(1) + <string>state.peek();
            state.lexeme = "!";
            return true;
        }

        // If the tag handle contains a hexadecimal escape,
        // Then the tag is primary
        if differentiate && state.peek() == "%" {
            check scanUnicodeEscapedCharacters(state, "%", 2);
            state.lexemeBuffer = state.lexeme.substring(1);
            state.lexeme = "!";
            return true;
        }

        // Store the complete primary tag if a white space is detected
        if differentiate && matchRegexPattern(state, WHITESPACE_PATTERN) {
            state.forward(-1);
            state.lexemeBuffer = state.lexeme.substring(1);
            state.lexeme = "!";
            return true;
        }

        return generateInvalidCharacterError(state, TAG_HANDLE);
    };
}

# Scan the lexeme for the anchor name.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token. An error on failure.
function scanAnchorName(LexerState state) returns boolean|LexicalError {
    // Check for mapping value with a space after it 
    if state.peek() == ":" {
        if !matchRegexPattern(state, [PRINTABLE_PATTERN], [LINE_BREAK_PATTERN, BOM_PATTERN, FLOW_INDICATOR_PATTERN, WHITESPACE_PATTERN], 1) {
            return true;
        }
    }

    if matchRegexPattern(state, [PRINTABLE_PATTERN], [LINE_BREAK_PATTERN, BOM_PATTERN, FLOW_INDICATOR_PATTERN, WHITESPACE_PATTERN]) {
        state.lexeme += <string>state.peek();
        return false;
    }
    return true;
}

# Scan the white spaces for a line-in-separation.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token.
function scanWhitespace(LexerState state) returns boolean {
    if state.peek() == " " {
        return false;
    }
    if state.peek() == "\t" {
        state.tabInWhitespace = true;
        return false;
    }
    return true;
}

# Check for the lexemes to crete an DECIMAL token.
#
# + state - Current lexer state
# + return - Generates a function which checks the lexemes for the given number system.
function scanDigit(LexerState state) returns boolean|LexicalError {
    if matchRegexPattern(state, DECIMAL_DIGIT_PATTERN) {
        state.lexeme += <string>state.peek();
        return false;
    }
    if state.peek() == " " || state.peek() == "\t" || state.peek() == "." {
        return true;
    }
    return generateInvalidCharacterError(state, "Digit");
}

# Differentiate the planar and anchor keys against the key of a mapping.
#
# + state - Current lexer state
# + outputToken - Planar or anchor key
# + process - Function to scan the lexeme
# + return - Returns the tokenized state with correct YAML token
function scanMappingValueKey(LexerState state, YAMLToken outputToken, function (LexerState state) returns boolean|LexicalError process) returns LexerState|LexicalError {
    LexicalError? err = assertIndent(state, 1);
    boolean enforceMapping = state.enforceMapping;
    state.enforceMapping = false;

    state.updateStartIndex();
    LexerState token = check iterate(state, process, outputToken);

    if state.isFlowCollection() {
        return token;
    }

    // Ignore whitespace until a character is found
    int numWhitespace = 0;
    while state.peek() == " " {
        numWhitespace += 1;
        state.forward();
    }

    if err is LexicalError { // Not sufficient indent to process as a value token
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

# Differentiate the single and double quoted keys against the key of a mapping.
#
# + state - Current lexer state
# + outputToken - Single or double quoted keys
# + return - Returns the tokenized state with correct YAML token
function scanMappingValueKeyWithDelimiter(LexerState state, YAMLToken outputToken) returns LexerState|LexicalError {
    LexerState token = state.tokenize(outputToken);
    boolean enforceMapping = state.enforceMapping;
    state.enforceMapping = false;

    // Ignore whitespace until a character is found
    int numWhitespace = 0;
    while state.peek() == " " {
        numWhitespace += 1;
        state.forward();
    }

    if state.isFlowCollection() {
        return token;
    }

    if state.index < state.indentStartIndex { // Not sufficient indent to process as a value token
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

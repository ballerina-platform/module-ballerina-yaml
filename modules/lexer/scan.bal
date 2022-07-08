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
        if matchPattern(state, patternHexadecimal) {
            unicodeDigits += <string>state.peek();
            continue;
        }
        return generateInvalidCharacterError(state, "<unicode-hex-escape>");
    }

    // Check if the lexeme can be converted to hexadecimal
    int|error hexResult = int:fromHexString(unicodeDigits);
    if hexResult is error {
        return generateScanningError(state, error:message(hexResult));
    }

    // Check if there exists a unicode string for the hexadecimal value
    string|error unicodeResult = string:fromCodePointInt(hexResult);
    if unicodeResult is error {
        return generateScanningError(state, string `Invalid hex escape value, '${unicodeDigits}'`);
    }

    state.lexeme += unicodeResult;
}

# Process double quoted scalar values.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token. An error on failure.
function scanDoubleQuoteChar(LexerState state) returns boolean|LexicalError {
    // Process nb-json characters
    if matchPattern(state, patternJson, ["\\", "\""]) {
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
    if matchPattern(state, patternJson, "'") {
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
    while isWhitespace(state) {
        whitespace += <string>state.peek();
        numWhitespace += 1;
        state.forward();
    }

    // Step back from the white spaces if EOL or ':' is reached 
    if state.peek() == () || state.peek() == "\n" {
        state.forward(-numWhitespace);
        return true;
    }

    // Terminate when the flow indicators are detected inside flow style collections
    if matchPattern(state, patternFlowIndicator) && state.isFlowCollection() {
        return true;
    }

    // Process ns-plain-safe character
    if matchPattern(state, patternPrintable, [patternLineBreak, patternBom, patternWhitespace, "#", ":"]) {
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
        if !discernPlanarFromIndicator(state) {
            state.forward(-numWhitespace);
            return true;
        }
        state.lexeme += whitespace + ":";
        return false;
    }

    return generateInvalidCharacterError(state, PLANAR_CHAR);
}

# Scan the lexeme for printable char.
#
# + allowWhitespace - Flag is set if whitespace is allowed as a printable char
# + return - False to continue. True to terminate the token. An error on failure.
function scanPrintableChar(boolean allowWhitespace) returns function (LexerState state) returns boolean|LexicalError {
    return function(LexerState state) returns boolean|LexicalError {
        if matchPattern(state, allowWhitespace ? [patternLineBreak] : [patternWhitespace, patternLineBreak]) {
            return true;
        }

        if matchPattern(state, patternPrintable, [patternBom, patternLineBreak]) {
            state.lexeme += <string>state.peek();
            return false;
        }

        return generateInvalidCharacterError(state, "<printable-char>");
    };
}

# Scan the lexeme for tag characters.
#
# + state - Current lexer state
# + return - False to continue. True to terminate the token. An error on failure.
function scanTagCharacter(LexerState state) returns boolean|LexicalError {
    // Check for URI character
    if matchPattern(state, [patternUri, patternWord], ["!", patternFlowIndicator]) {
        state.lexeme += <string>state.peek();
        return false;
    }

    // Terminate if a whitespace or a flow indicator is detected
    if matchPattern(state, [patternWhitespace, patternFlowIndicator]) {
        return true;
    }

    // Process the hexadecimal values after '%'
    if state.peek() == "%" {
        check scanUnicodeEscapedCharacters(state, "%", 2);
        return false;
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
        if matchPattern(state, [patternUri, patternWord]) {
            state.lexeme += <string>state.peek();
            return false;
        }

        // Process the hexadecimal values after '%'
        if state.peek() == "%" {
            check scanUnicodeEscapedCharacters(state, "%", 2);
            return false;
        }

        // Ignore the comments
        if matchPattern(state, [patternLineBreak, patternWhitespace]) {
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
        if matchPattern(state, [patternWord, patternUri], ["!", patternFlowIndicator]) {
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

        // Store the complete primary tag if a white space or a flow indicator is detected.
        if differentiate && matchPattern(state, [patternFlowIndicator, patternWhitespace]) {
            state.forward(-1);
            state.lexemeBuffer = state.lexeme.substring(1);
            state.lexeme = "!";
            return true;
        }

        // Store the complete primary tag if a hexadecimal escape is detected.
        if differentiate && state.peek() == "%" {
            check scanUnicodeEscapedCharacters(state, "%", 2);
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
    if matchPattern(state, [patternPrintable], [patternLineBreak, patternBom, patternFlowIndicator, patternWhitespace]) {
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
        state.updateFirstTabIndex();
        return false;
    }
    return true;
}

# Check for the lexemes to crete an DECIMAL token.
#
# + state - Current lexer state
# + return - Generates a function which checks the lexemes for the given number system.
function scanDigit(LexerState state) returns boolean|LexicalError {
    if matchPattern(state, patternDecimal) {
        state.lexeme += <string>state.peek();
        return false;
    }
    if isWhitespace(state) || state.peek() == "." {
        return true;
    }
    return generateInvalidCharacterError(state, "Digit");
}

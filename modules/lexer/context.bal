import yaml.common;

# Represents the current context of the Lexer.
public enum Context {
    LEXER_START,
    LEXER_EXPLICIT_KEY,
    LEXER_TAG_HANDLE,
    LEXER_TAG_PREFIX,
    LEXER_TAG_NODE,
    LEXER_DIRECTIVE,
    LEXER_DOUBLE_QUOTE,
    LEXER_SINGLE_QUOTE,
    LEXER_BLOCK_HEADER,
    LEXER_LITERAL
}

# Scan the lexemes for double quoted scalars.
#
# + state - Current lexer state.
# + return - Tokenized double quoted scalar
function contextDoubleQuote(LexerState state) returns LexerState|LexicalError {
    // Check for empty lines
    if state.peek() == " " {
        _ = check iterate(state, scanWhitespace, SEPARATION_IN_LINE);
        if state.peek() == () {
            return state.tokenize(EMPTY_LINE);
        }
    }

    // Terminating delimiter
    if state.peek() == "\"" {
        return scanMappingValueKeyWithDelimiter(state, DOUBLE_QUOTE_DELIMITER);
    }

    // Regular double quoted characters
    if matchRegexPattern(state, JSON_PATTERN, exclusionPatterns = ["\""]) {
        return iterate(state, scanDoubleQuoteChar, DOUBLE_QUOTE_CHAR);
    }

    return generateInvalidCharacterError(state, "double-quoted flow style");
}

# Scan the lexemes for single quoted scalars.
#
# + state - Current lexer state.
# + return - Tokenized single quoted scalar
function contextSingleQuote(LexerState state) returns LexerState|LexicalError {
    // Check for empty lines
    if state.peek() == " " {
        _ = check iterate(state, scanWhitespace, SEPARATION_IN_LINE);
        if state.peek() == () {
            return state.tokenize(EMPTY_LINE);
        }
    }

    // Escaped single quote
    if state.peek() == "'" && state.peek(1) == "'" {
        state.lexeme += "'";
        state.forward(2);
    }

    // Terminating delimiter
    if state.peek() == "'" {
        if state.lexeme.length() > 0 {
            state.index -= 1;
            return state.tokenize(SINGLE_QUOTE_CHAR);
        }
        return scanMappingValueKeyWithDelimiter(state, SINGLE_QUOTE_DELIMITER);
    }

    // Regular single quoted characters
    if matchRegexPattern(state, JSON_PATTERN, exclusionPatterns = ["'"]) {
        return iterate(state, scanSingleQuotedChar, SINGLE_QUOTE_CHAR);
    }

    return generateInvalidCharacterError(state, "single-quoted flow style");
}

# Scan the lexemes for YAML version directive.
#
# + state - Current lexer state.
# + return - Tokenized YAML version directive
function contextYamlDirective(LexerState state) returns LexerState|LexicalError {
    // Ignore any comments
    if state.peek() == "#" {
        state.forward(-1);
        return state.tokenize(EOL);
    }

    // Check for decimal digits
    if (matchRegexPattern(state, DECIMAL_DIGIT_PATTERN)) {
        return iterate(state, scanDigit(DECIMAL_DIGIT_PATTERN), DECIMAL);
    }

    // Check for decimal point
    if state.peek() == "." {
        return state.tokenize(DOT);
    }

    return generateInvalidCharacterError(state, "version number");
}

# Scan the lexemes that are without any explicit context.
#
# + state - Current lexer state.
# + return - Tokenized token
function contextStart(LexerState state) returns LexerState|LexicalError {
    match state.peek() {
        " " => {
            // Return empty line if there is only whitespace
            // Else, return separation in line
            boolean isFirstChar = state.index == 0;
            _ = check iterate(state, scanWhitespace, SEPARATION_IN_LINE);
            return (state.peek() == () && isFirstChar) ? state.tokenize(EMPTY_LINE) : state;
        }
        "#" => { // Ignore comments
            state.forward(-1);
            return state.tokenize(EOL);
        }
    }

    if (matchRegexPattern(state, BOM_PATTERN)) {
        return state.tokenize(BOM);
    }

    match state.peek() {
        "-" => {
            // Scan for directive marker
            if state.peek(1) == "-" && state.peek(2) == "-" {
                state.forward(2);
                return state.tokenize(DIRECTIVE_MARKER);
            }

            // Scan for planar characters
            if matchRegexPattern(state, [PRINTABLE_PATTERN], [LINE_BREAK_PATTERN, BOM_PATTERN, WHITESPACE_PATTERN], 1) {
                state.forward();
                state.lexeme += "-";
                return iterate(state, scanPlanarChar, PLANAR_CHAR);
            }

            // Return block sequence entry
            _ = state.tokenize(SEQUENCE_ENTRY);
            state.indentation = check checkIndent(state);
            return state;
        }
        "." => {
            // Scan for directive marker
            if state.peek(1) == "." && state.peek(2) == "." {
                state.forward(2);
                return state.tokenize(DOCUMENT_MARKER);
            }

            // Scan for planar characters
            state.forward();
            state.lexeme += ".";
            return iterate(state, scanPlanarChar, PLANAR_CHAR);
        }
        "*" => {
            state.forward();
            return scanMappingValueKey(state, ALIAS, scanAnchorName);
        }
        "%" => { // Directive line
            state.forward();
            match state.peek() {
                "T" => {
                    return check tokensInSequence(state, "TAG", DIRECTIVE);
                }
                "Y" => {
                    return check tokensInSequence(state, "YAML", DIRECTIVE);
                }
                _ => {
                    return generateInvalidCharacterError(state, DIRECTIVE);
                }
            }
        }
        "!" => { // Node tags
            check assertIndent(state, 1);
            match state.peek(1) {
                "<" => { // Verbatim tag
                    state.forward(2);

                    if state.peek() == "!" && state.peek(1) == ">" {
                        return generateScanningError(state, "'verbatim tag' are not resolved. Hence, '!' is invalid");
                    }

                    return matchRegexPattern(state, [URI_CHAR_PATTERN, WORD_PATTERN]) ?
                            iterate(state, scanURICharacter(true), TAG, true)
                            : generateScanningError(state, "Expected a 'uri-char' after '<' in a 'verbatim tag'");
                }
                " "|"\t"|() => { // Non-specific tag
                    state.lexeme = "!";
                    state.forward();
                    return state.tokenize(TAG);
                }
                "!" => { // Secondary tag handle 
                    state.lexeme = "!!";
                    state.forward();
                    return state.tokenize(TAG_HANDLE);
                }
                _ => { // Check for primary and name tag handles
                    state.lexeme = "!";
                    state.forward();

                    // Differentiate between primary and named tag
                    return iterate(state, scanTagHandle(true), TAG_HANDLE, true);
                }
            }
        }
        "&" => {
            check assertIndent(state, 1);
            state.forward();
            return iterate(state, scanAnchorName, ANCHOR);
        }
        ":" => {
            if !state.isJsonKey && matchRegexPattern(state, [PRINTABLE_PATTERN], [LINE_BREAK_PATTERN, BOM_PATTERN, WHITESPACE_PATTERN], 1) {
                state.lexeme += ":";
                state.forward();
                return iterate(state, scanPlanarChar, PLANAR_CHAR);
            }
            _ = state.tokenize(MAPPING_VALUE);

            // Capture the for empty key mapping values
            if (state.index == 0 || state.line.trim()[0] == ":") && state.numOpenedFlowCollections == 0 {
                state.indentation = check checkIndent(state, state.index - 1);
            }
            return state;
        }
        "?" => {
            if matchRegexPattern(state, [PRINTABLE_PATTERN], [LINE_BREAK_PATTERN, BOM_PATTERN, WHITESPACE_PATTERN], 1) {
                state.lexeme += "?";
                state.forward();
                return iterate(state, scanPlanarChar, PLANAR_CHAR);
            }
            _ = state.tokenize(MAPPING_KEY);

            // Capture the for empty key mapping values
            if state.numOpenedFlowCollections == 0 {
                state.indentation = check checkIndent(state, state.index - 1);
            }
            return state;
        }
        "\"" => { // Process double quote flow style value
            state.delimiterStartIndex = state.index;
            return state.tokenize(DOUBLE_QUOTE_DELIMITER);
        }
        "'" => {
            state.delimiterStartIndex = state.index;
            return state.tokenize(SINGLE_QUOTE_DELIMITER);
        }
        "," => {
            //TODO: only valid in flow sequence
            return state.tokenize(SEPARATOR);
        }
        "[" => {
            check assertIndent(state, 1);
            state.numOpenedFlowCollections += 1;
            return state.tokenize(SEQUENCE_START);
        }
        "]" => {
            state.numOpenedFlowCollections -= 1;
            return state.tokenize(SEQUENCE_END);
        }
        "{" => {
            check assertIndent(state, 1);
            state.numOpenedFlowCollections += 1;
            return state.tokenize(MAPPING_START);
        }
        "}" => {
            state.numOpenedFlowCollections -= 1;
            return state.tokenize(MAPPING_END);
        }
        "|"|">" => { // Block scalars
            state.addIndent = 1;
            state.captureIndent = true;
            return state.tokenize(state.peek() == "|" ? LITERAL : FOLDED);
        }
    }

    // Check for first character of planar scalar
    if isPlainSafe(state) {
        return scanMappingValueKey(state, PLANAR_CHAR, scanPlanarChar);
    }

    return generateInvalidCharacterError(state, "<yaml-document>");
}

# Scan the lexemes for Explicit key scalar.
#
# + state - Current lexer state.
# + return - Tokenized Explicit key scalar
function contextExplicitKey(LexerState state) returns LexerState|LexicalError {
    match state.peek() {
        " " => {
            // Return empty line if there is only whitespace
            // Else, return separation in line
            boolean isFirstChar = state.index == 0;
            _ = check iterate(state, scanWhitespace, SEPARATION_IN_LINE);
            return (state.peek() == () && isFirstChar) ? state.tokenize(EMPTY_LINE) : state;
        }
        "#" => { // Ignore comments
            return state.tokenize(EOL);
        }
        ":" => {
            if state.numOpenedFlowCollections > 0 {
                return state.tokenize(MAPPING_VALUE);
            }

            // Mapping value and mapping key should have the same indent.
            if state.indents[state.indents.length() - 1].index == state.index {
                return state.tokenize(MAPPING_VALUE);
            }
            return generateIndentationError(state, "Invalid indentation for an explicit key");
        }
    }

    if isPlainSafe(state) {
        if state.numOpenedFlowCollections == 0 {
            check assertIndent(state, 1);
        }
        return iterate(state, scanPlanarChar, PLANAR_CHAR);
    }

    return contextStart(state);
}

# Scan the lexemes for YAML tag handle directive.
#
# + state - Current lexer state.
# + return - Tokenized YAML tag handle directive
function contextTagHandle(LexerState state) returns LexerState|LexicalError {
    // Ignore any comments
    if state.peek() == "#" {
        state.forward(-1);
        return state.tokenize(EOL);
    }

    // Check fo primary, secondary, and named tag handles
    if state.peek() == "!" {
        match state.peek(1) {
            " "|"\t" => { // Primary tag handle
                state.lexeme = "!";
                return state.tokenize(TAG_HANDLE);
            }
            "!" => { // Secondary tag handle
                state.lexeme = "!!";
                state.forward();
                return state.tokenize(TAG_HANDLE);
            }
            () => {
                return generateScanningError(state, string `Expected a ${SEPARATION_IN_LINE} after primary tag handle`);
            }
            _ => { // Check for named tag handles
                state.lexeme = "!";
                state.forward();
                return iterate(state, scanTagHandle(), TAG_HANDLE, true);
            }
        }
    }

    // Check for separation-in-space before the tag prefix
    if state.peek() == " " {
        return check iterate(state, scanWhitespace, SEPARATION_IN_LINE);
    }

    return generateScanningError(state, "Expected '!' to start the tag handle");
}

# Scan the lexemes for YAML tag prefix directive.
#
# + state - Current lexer state.
# + return - Tokenized YAML tag prefix directive
function contextTagPrefix(LexerState state) returns LexerState|LexicalError {
    // Ignore any comments
    if state.peek() == "#" {
        state.forward(-1);
        return state.tokenize(EOL);
    }

    // Match the global tag prefix or local tag prefix
    if matchRegexPattern(state, [URI_CHAR_PATTERN, WORD_PATTERN], exclusionPatterns = ["!", FLOW_INDICATOR_PATTERN])
        || state.peek() == "!" {
        return iterate(state, scanURICharacter(), TAG_PREFIX);
    }

    // Match the global prefix with hexadecimal value
    if state.peek() == "%" {
        check scanUnicodeEscapedCharacters(state, "%", 2);
        state.forward();
        return iterate(state, scanURICharacter(), TAG_PREFIX);
    }

    // Check for tail separation-in-line
    if state.peek() == " " {
        return check iterate(state, scanWhitespace, SEPARATION_IN_LINE);
    }

    return generateInvalidCharacterError(state, TAG_PREFIX);
}

# Scan the lexemes for tag node properties.
#
# + state - Current lexer state.
# + return - Tokenized tag node properties
function contextTagNode(LexerState state) returns LexerState|LexicalError {
    // Scan the anchor node
    if state.peek() == "&" {
        state.forward();
        return iterate(state, scanAnchorName, ANCHOR);
    }

    // Match the tag with the t ag character pattern
    if matchRegexPattern(state, [URI_CHAR_PATTERN, WORD_PATTERN], exclusionPatterns = ["!", FLOW_INDICATOR_PATTERN]) {
        return iterate(state, scanTagCharacter, TAG);
    }

    // Match the global prefix with hexadecimal value
    if state.peek() == "%" {
        check scanUnicodeEscapedCharacters(state, "%", 2);
        state.forward();
        return iterate(state, scanURICharacter(), TAG_PREFIX);
    }

    // Check for tail separation-in-line
    if state.peek() == " " {
        return check iterate(state, scanWhitespace, SEPARATION_IN_LINE);
    }

    return generateInvalidCharacterError(state, TAG);
}

# Scan the lexemes for block header of a block scalar.
#
# + state - Current lexer state.
# + return - Tokenized block header
function contextBlockHeader(LexerState state) returns LexerState|LexicalError {
    // Check for indentation indicators and adjust the current indent
    if matchRegexPattern(state, "1-9") {
        state.captureIndent = false;
        state.addIndent += <int>(check common:processTypeCastingError('int:fromString(<string>state.peek()))) - 1;
        state.forward();
    }

    // If the indentation indicator is at the tail
    if (state.index >= state.line.length()) {
        return state.tokenize(EOL);
    }

    // Check for chomping indicators
    if checkCharacter(state, ["+", "-"]) {
        state.lexeme = <string>state.peek();
        return state.tokenize(CHOMPING_INDICATOR);
    }

    return generateInvalidCharacterError(state, "<block-header>");
}

# Scan the lexemes for block scalar.
#
# + state - Current lexer state.
# + return - Tokenized block scalar
function contextBlockScalar(LexerState state) returns LexerState|LexicalError {

    // Check if the line has sufficient indent to be process as a block scalar.
    boolean hasSufficientIndent = true;
    foreach int i in 0 ... (state.indent < 0 ? 0 : state.indent) + state.addIndent - 1 {
        if !(state.peek() == " ") {
            hasSufficientIndent = false;
            break;
        }
        state.forward();
    }

    // There is no sufficient indent to consider printable characters
    if !hasSufficientIndent {
        if isPlainSafe(state) {
            state.enforceMapping = true;
            return contextStart(state);
        }

        match state.peek() {
            "#" => { // Generate beginning of the trailing comment
                return state.trailingComment ? state.tokenize(EOL) : state.tokenize(TRAILING_COMMENT);
            }
            "'"|"\"" => { // Possible flow scalar
                state.enforceMapping = true;
                return contextStart(state);
            }
            ":" => {
                return contextStart(state);
            }
            "-" => { // Possible sequence entry
                return contextStart(state);
            }
            () => { // Empty lines are allowed in trailing comments
                return state.tokenize(EMPTY_LINE);
            }
            _ => { // Other characters are not allowed when the indentation is less
                return generateIndentationError(state, "Insufficient indent to process literal characters");
            }
        }
    }

    if state.trailingComment {
        while true {
            match state.peek() {
                " " => { // Ignore whitespace
                    state.forward();
                }
                "#" => { // Generate beginning of the trailing comment
                    return state.tokenize(EOL);
                }
                () => { // Empty lines are allowed in trailing comments
                    return state.tokenize(EMPTY_LINE);
                }
                _ => {
                    return generateInvalidCharacterError(state, TRAILING_COMMENT);
                }
            }
        }
    }

    // Generate an empty lines that have less index.
    if (state.index >= state.line.length()) {
        return state.tokenize(EMPTY_LINE);
    }

    // Update the indent to the first line
    if state.captureIndent {
        int additionalIndent = 0;

        while state.peek() == " " {
            additionalIndent += 1;
            state.forward();
        }

        state.addIndent += additionalIndent;
        state.captureIndent = false;
    }

    // Scan printable character
    if matchRegexPattern(state, PRINTABLE_PATTERN, [BOM_PATTERN, LINE_BREAK_PATTERN]) {
        return iterate(state, scanPrintableChar, PRINTABLE_CHAR);
    }


    return generateInvalidCharacterError(state, LITERAL);
}

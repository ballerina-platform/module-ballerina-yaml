enum RegexPattern {
    PRINTABLE_PATTERN = "\\x09\\x0a\\x0d\\x20-\\x7e\\x85\\xa0-\\ud7ff\\ue000-\\ufffd",
    JSON_PATTERN = "\\x09\\x20-\\uffff",
    BOM_PATTERN = "\\ufeff",
    DECIMAL_DIGIT_PATTERN = "0-9",
    HEXADECIMAL_DIGIT_PATTERN = "0-9a-fA-F",
    OCTAL_DIGIT_PATTERN = "0-7",
    BINARY_DIGIT_PATTERN = "0-1",
    LINE_BREAK_PATTERN = "\\x0a\\x0d",
    WORD_PATTERN = "a-zA-Z0-9\\-",
    FLOW_INDICATOR_PATTERN = "\\,\\[\\]\\{\\}",
    WHITESPACE_PATTERN = "\\s\\t",
    URI_CHAR_PATTERN = "#;/\\?:@&=\\+\\$,_\\.!~\\*'\\(\\)\\[\\]",
    INDICATOR_PATTERN = "\\-\\?:\\,\\[\\]\\{\\}#&\\*!\\|\\>\\'\\\"%@\\`"
}

final readonly & map<string> escapedCharMap = {
    "0": "\u{00}",
    "a": "\u{07}",
    "b": "\u{08}",
    "t": "\t",
    "n": "\n",
    "v": "\u{0b}",
    "f": "\u{0c}",
    "r": "\r",
    "e": "\u{1b}",
    "\"": "\"",
    "/": "/",
    "\\": "\\",
    "N": "\u{85}",
    "_": "\u{a0}",
    "L": "\u{2028}",
    "P": "\u{2029}",
    " ": "\u{20}"
};

# Generates a Token for the next immediate lexeme.
#
# + return - If success, returns a token, else returns a Lexical Error 
public function scan(LexerState state) returns LexerState|LexicalError {

    // Check the lexeme buffer for the lexeme stored by the primary tag
    if state.lexemeBuffer.length() > 0 {
        state.lexeme = state.lexemeBuffer;
        state.lexemeBuffer = "";

        // Reaches the end-of-line and the primary tag is stored in the buffer
        if state.peek() == () {
            return state.tokenize(TAG);
        }

        // The complete primary tag is stored in the buffer
        if matchRegexPattern(state, WHITESPACE_PATTERN) {
            state.forward(-1);
            return state.tokenize(TAG);
        }

        // A first portion of the primary tag is stored in the buffer
        if matchRegexPattern(state, [URI_CHAR_PATTERN, WORD_PATTERN], ["!", FLOW_INDICATOR_PATTERN]) {
            return iterate(state, scanTagCharacter, TAG);
        }

        return generateError(state, formatErrorMessage(<string>state.peek(), "primary tag"));
    }

    // Generate EOL token at the last index
    if (state.index >= state.line.length()) {
        return state.index == 0 ? state.tokenize(EMPTY_LINE) : state.tokenize(EOL);
    }

    if (matchRegexPattern(state, LINE_BREAK_PATTERN)) {
        return state.tokenize(LINE_BREAK);
    }

    match state.context {
        LEXER_START => {
            return contextStart(state);
        }
        LEXER_EXPLICIT_KEY => {
            return contextExplicitKey(state);
        }
        LEXER_TAG_HANDLE => {
            return contextTagHandle(state);
        }
        LEXER_TAG_PREFIX => {
            return contextTagPrefix(state);
        }
        LEXER_TAG_NODE => {
            return contextTagNode(state);
        }
        LEXER_DIRECTIVE => {
            return contextYamlDirective(state);
        }
        LEXER_DOUBLE_QUOTE => {
            return contextDoubleQuote(state);
        }
        LEXER_SINGLE_QUOTE => {
            return contextSingleQuote(state);
        }
        LEXER_BLOCK_HEADER => {
            return contextBlockHeader(state);
        }
        LEXER_LITERAL => {
            return contextBlockScalar(state);
        }
        _ => {
            return generateError(state, "Invalid state");
        }
    }

}

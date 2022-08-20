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
    " ": "\u{20}",
    "\t": "\t"
};

# Generates a Token for the next immediate lexeme.
#
# + state - Current lexer state
# + return - If success, returns a token, else returns a Lexical Error
public function scan(LexerState state) returns LexerState|LexicalError {

    // Check the lexeme buffer for the lexeme stored by the primary tag
    if state.lexemeBuffer.length() > 0 {
        state.lexeme = state.lexemeBuffer;
        state.lexemeBuffer = "";

        // If lexeme buffer contains only up to a hexadecimal value,
        // then check for the remaining content of the primary tag.
        if isTagChar(state) {
            return iterate(state, scanTagCharacter, TAG);
        }

        state.forward(-1);
        return state.tokenize(TAG);
    }

    // Generate EOL token at the last index
    if state.peek() == () {
        if state.indentationBreak {
            return generateIndentationError(state, "Invalid indentation");
        }
        return state.index == 0 ? state.tokenize(EMPTY_LINE) : state.tokenize(EOL);
    }

    // Check for line breaks when reading form string
    if state.peek() == "\n" && state.context != LEXER_DOUBLE_QUOTE {
        state.isNewLine = true;
        return state.tokenize(EOL);
    }

    match state.context {
        LEXER_START => {
            return contextStart(state);
        }
        LEXER_TAG_HANDLE => {
            return contextTagHandle(state);
        }
        LEXER_TAG_PREFIX => {
            return contextTagPrefix(state);
        }
        LEXER_NODE_PROPERTY => {
            return contextNodeProperty(state);
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
        LEXER_RESERVED_DIRECTIVE => {
            return contextReservedDirective(state);
        }
        _ => {
            return generateScanningError(state, "Invalid context for the lexer");
        }
    }
}

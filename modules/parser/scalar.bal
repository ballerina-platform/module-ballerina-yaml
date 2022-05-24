import yaml.lexer;

# Parse the string of a double-quoted scalar.
#
# + state - Current parser state
# + return - Parsed double-quoted scalar value
function doubleQuoteScalar(ParserState state) returns ParsingError|string {
    state.updateLexerContext(lexer:LEXER_DOUBLE_QUOTE);
    string lexemeBuffer = "";
    boolean isFirstLine = true;
    boolean emptyLine = false;
    boolean escaped = false;

    check checkToken(state);

    // Iterate the content until the delimiter is found
    while state.currentToken.token != lexer:DOUBLE_QUOTE_DELIMITER {
        match state.currentToken.token {
            lexer:DOUBLE_QUOTE_CHAR => { // Regular double quoted string char
                string lexeme = state.currentToken.value;

                // Check for double escaped character
                if lexeme.length() > 0 && lexeme[lexeme.length() - 1] == "\\" {
                    escaped = true;
                    lexemeBuffer += lexeme.substring(0, lexeme.length() - 1);
                } else if !isFirstLine {
                    if escaped {
                        escaped = false;
                    } else { // Trim the white space if not escaped
                        if !emptyLine { // Add a white space if there are not preceding empty lines
                            lexemeBuffer += " ";
                        }
                    }
                    lexemeBuffer += lexeme;
                } else {
                    lexemeBuffer += lexeme;
                }

                if emptyLine {
                    emptyLine = false;
                }
            }
            lexer:EOL => { // Processing new lines
                if !escaped { // If not escaped, trim the trailing white spaces
                    lexemeBuffer = trimTailWhitespace(lexemeBuffer, state.lexerState.lastEscapedChar);
                }

                isFirstLine = false;
                check state.initLexer("Expected to end the multi-line double string");

                // Add a whitespace if the delimiter is on a new line
                check checkToken(state, peek = true);
                if state.tokenBuffer.token == lexer:DOUBLE_QUOTE_DELIMITER && !emptyLine {
                    lexemeBuffer += " ";
                }
            }
            lexer:EMPTY_LINE => {
                if isFirstLine { // Whitespace is preserved on the first line
                    lexemeBuffer += state.currentToken.value;
                    isFirstLine = false;
                } else if escaped { // Whitespace is preserved when escaped
                    lexemeBuffer += state.currentToken.value + "\n";
                } else { // Whitespace is ignored when line folding
                    lexemeBuffer = trimTailWhitespace(lexemeBuffer);
                    lexemeBuffer += "\n";
                }
                emptyLine = true;
                check state.initLexer("Expected to end the multi-line double-quoted scalar");
            }
            _ => {
                return generateInvalidTokenError(state, "double-quoted scalar");
            }
        }
        check checkToken(state);
    }

    check verifyKey(state, isFirstLine);
    return lexemeBuffer;
}

# Parse the string of a single-quoted scalar.
#
# + state - Current parser state
# + return - Parsed single-quoted scalar value
function singleQuoteScalar(ParserState state) returns ParsingError|string {
    state.updateLexerContext(lexer:LEXER_SINGLE_QUOTE);
    string lexemeBuffer = "";
    boolean isFirstLine = true;
    boolean emptyLine = false;

    check checkToken(state);

    // Iterate the content until the delimiter is found
    while state.currentToken.token != lexer:SINGLE_QUOTE_DELIMITER {
        match state.currentToken.token {
            lexer:SINGLE_QUOTE_CHAR => {
                string lexeme = state.currentToken.value;

                if isFirstLine {
                    lexemeBuffer += lexeme;
                } else {
                    if emptyLine {
                        emptyLine = false;
                    } else { // Add a white space if there are not preceding empty lines
                        lexemeBuffer += " ";
                    }
                    lexemeBuffer += trimHeadWhitespace(lexeme);
                }
            }
            lexer:EOL => {
                // Trim trailing white spaces
                lexemeBuffer = trimTailWhitespace(lexemeBuffer);
                isFirstLine = false;
                check state.initLexer("Expected to end the multi-line double string");

                // Add a whitespace if the delimiter is on a new line
                check checkToken(state, peek = true);
                if state.tokenBuffer.token == lexer:SINGLE_QUOTE_DELIMITER && !emptyLine {
                    lexemeBuffer += " ";
                }
            }
            lexer:EMPTY_LINE => {
                if isFirstLine { // Whitespace is preserved on the first line
                    lexemeBuffer += state.currentToken.value;
                    isFirstLine = false;
                } else { // Whitespace is ignored when line folding
                    lexemeBuffer = trimTailWhitespace(lexemeBuffer);
                    lexemeBuffer += "\n";
                }
                emptyLine = true;
                check state.initLexer("Expected to end the multi-line single-quoted scalar");
            }
            _ => {
                return generateInvalidTokenError(state, "single-quoted scalar");
            }
        }
        check checkToken(state);
    }

    check verifyKey(state, isFirstLine);
    return lexemeBuffer;
}

# Parse the string of a planar scalar.
#
# + state - Current parser state
# + return - Parsed planar scalar value
function planarScalar(ParserState state) returns ParsingError|string {
    // Process the first planar char
    string lexemeBuffer = state.currentToken.value;
    boolean isFirstLine = true;
    string newLineBuffer = "";

    check checkToken(state, peek = true);

    // Iterate the content until an invalid token is found
    while true {
        match state.tokenBuffer.token {
            lexer:PLANAR_CHAR => {
                if state.tokenBuffer.indentation != () {
                    break;
                }
                check checkToken(state);
                if newLineBuffer.length() > 0 {
                    lexemeBuffer += newLineBuffer;
                    newLineBuffer = "";
                } else { // Add a whitespace if there are no preceding empty lines
                    lexemeBuffer += " ";
                }
                lexemeBuffer += state.currentToken.value;
            }
            lexer:EOL => {
                check checkToken(state);

                // Terminate at the end of the line
                if state.lineIndex == state.numLines - 1 {
                    break;
                }
                check state.initLexer();

                // Keys are allowed if the mapping value is next line
                check checkToken(state, peek = true);
                if state.tokenBuffer.token == lexer:MAPPING_VALUE && state.lexerState.isFlowCollection() {
                    break;
                }

                isFirstLine = false;
            }
            lexer:EMPTY_LINE => {
                newLineBuffer += "\n";
                check checkToken(state);
                // Terminate at the end of the line
                if state.lineIndex == state.numLines - 1 {
                    break;
                }
                check state.initLexer("");
            }
            lexer:SEPARATION_IN_LINE => {
                check checkToken(state);
                // Continue to scan planar char if the white space at the lexer:EOL
                check checkToken(state, peek = true);
                if state.tokenBuffer.token == lexer:MAPPING_VALUE {
                    break;
                }
            }
            _ => { // Break the character when the token does not belong to planar scalar
                break;
            }
        }
        check checkToken(state, peek = true);
    }

    check verifyKey(state, isFirstLine);
    return trimTailWhitespace(lexemeBuffer);
}

# Parse the string of a block scalar.
#
# + state - Current parser state  
# + isFolded - If set, then the parses folded block scalar. Else, parses literal block scalar.
# + return - Parsed block scalar value
function blockScalar(ParserState state, boolean isFolded) returns ParsingError|string {
    string chompingIndicator = "";
    state.updateLexerContext(lexer:LEXER_BLOCK_HEADER);
    check checkToken(state);

    // Scan for block-header
    match state.currentToken.token {
        lexer:CHOMPING_INDICATOR => { // Strip and keep chomping indicators
            chompingIndicator = state.currentToken.value;
            check checkToken(state, lexer:EOL);

            if state.lineIndex < state.numLines - 1 {
                check state.initLexer();
            }
        }
        lexer:EOL => { // Clip chomping indicator
            check state.initLexer();
            chompingIndicator = "=";
        }
        _ => { // Any other characters are not allowed
            return generateExpectError(state, lexer:CHOMPING_INDICATOR, state.prevToken);
        }
    }

    state.updateLexerContext(lexer:LEXER_LITERAL);
    string lexemeBuffer = "";
    string newLineBuffer = "";
    boolean isFirstLine = true;
    boolean prevTokenIndented = false;

    check checkToken(state, peek = true);

    while true {
        match state.tokenBuffer.token {
            lexer:PRINTABLE_CHAR => {
                if !isFirstLine {
                    string suffixChar = "\n";
                    if isFolded && prevTokenIndented && state.tokenBuffer.value[0] != " " {
                        suffixChar = newLineBuffer.length() == 0 ? " " : "";
                    }
                    lexemeBuffer += newLineBuffer + suffixChar;
                    newLineBuffer = "";
                }

                lexemeBuffer += state.tokenBuffer.value;
                prevTokenIndented = state.tokenBuffer.value[0] != " ";
                isFirstLine = false;
            }
            lexer:EOL => {
                // Terminate at the end of the line
                if state.lineIndex == state.numLines - 1 {
                    break;
                }
                check state.initLexer();
            }
            lexer:EMPTY_LINE => {
                if !isFirstLine {
                    newLineBuffer += "\n";
                }
                if state.lineIndex == state.numLines - 1 {
                    break;
                }
                check state.initLexer();
                isFirstLine = false;
            }
            lexer:TRAILING_COMMENT => {
                state.lexerState.trailingComment = true;
                // Terminate at the end of the line
                if state.lineIndex == state.numLines - 1 {
                    break;
                }
                check state.initLexer();
                check checkToken(state);
                check checkToken(state, peek = true);

                // Ignore the tokens inside trailing comments
                while state.tokenBuffer.token == lexer:EOL || state.tokenBuffer.token == lexer:EMPTY_LINE {
                    // Terminate at the end of the line
                    if state.lineIndex == state.numLines - 1 {
                        break;
                    }
                    check state.initLexer();
                    check checkToken(state);
                    check checkToken(state, peek = true);
                }

                state.lexerState.trailingComment = false;
                break;
            }
            _ => { // Break the character when the token does not belong to planar scalar
                break;
            }
        }
        check checkToken(state);
        check checkToken(state, peek = true);
    }

    // Adjust the tail based on the chomping values
    match chompingIndicator {
        "-" => {
            //TODO: trim trailing newlines
        }
        "+" => {
            lexemeBuffer += "\n";
            lexemeBuffer += newLineBuffer;
        }
        "=" => {
            //TODO: trim trailing newlines
            lexemeBuffer += "\n";
        }
    }

    return lexemeBuffer;
}

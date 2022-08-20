# Encapsulate a function to run isolated on the remaining characters.
# Function lookahead to capture the lexemes for a targeted token.
#
# + state - Current lexer state
# + process - Function to be executed on each iteration  
# + successToken - Token to be returned on successful traverse of the characters  
# + message - Message to display if the end delimiter is not shown  
# + include - True when the last char belongs to the token
# + return - Lexical Error if available
function iterate(LexerState state, function (LexerState state) returns boolean|LexicalError process,
                            YAMLToken successToken,
                            boolean include = false,
                            string message = "") returns LexerState|LexicalError {

    // Iterate the given line to check the DFA
    while state.index < state.line.length() {
        if check process(state) {
            state.index = include ? state.index : state.index - 1;
            return state.tokenize(successToken);
        }
        state.forward();
    }
    state.index = state.line.length() - 1;

    // If the lexer does not expect an end delimiter at EOL, returns the token. Else it an error.
    return message.length() == 0 ? state.tokenize(successToken) : generateScanningError(state, message);
}

# Check if the given character matches the regex pattern.
#
# + state - Current lexer state
# + inclusionPattern - Included YAML patterns
# + offset - Offset of the character from the current index. Default = 0  
# + exclusionPattern - Excluded YAML patterns
# + return - True if the pattern matches
function matchPattern(LexerState state, patternParamterType|patternParamterType[] inclusionPattern,
    patternParamterType|patternParamterType[] exclusionPattern = [], int offset = 0) returns boolean {

    // If there is no character to check the pattern, then return false.
    if state.peek(offset) == () {
        return false;
    }
    string:Char currentChar = <string:Char>state.peek(offset);

    // Process the exclusion pattern
    if exclusionPattern is patternParamterType[] {
        foreach patternParamterType item in exclusionPattern {
            if checkPattern(currentChar, item) {
                return false;
            }
        }
    } else {
        if checkPattern(currentChar, exclusionPattern) {
            return false;
        }
    }

    // Process the inclusion pattern
    if inclusionPattern is patternParamterType[] {
        foreach patternParamterType item in inclusionPattern {
            if checkPattern(currentChar, item) {
                return true;
            }
        }
    } else {
        return checkPattern(currentChar, inclusionPattern);
    }

    return false;
}

function checkPattern(string:Char currentChar, patternParamterType pattern) returns boolean
    => pattern is string ? currentChar == pattern : pattern(currentChar);

# Assert the character of the current index
#
# + state - Current lexer state
# + expectedCharacters - Expected characters at the current index  
# + index - Index of the character. If null, takes the lexer's 
# + return - True if the assertion is true. Else, an lexical error
function checkCharacters(LexerState state, string[] expectedCharacters, int? index = ()) returns boolean
    => expectedCharacters.indexOf(state.line[index == () ? state.index : index]) is int;

# Returns true if the current character is planar safe.
#
# + state - Current lexer state/
# + return - Return true if a planar safe character is found.
function isPlainSafe(LexerState state) returns boolean
    => matchPattern(state, [patternPrintable], [patternLineBreak, patternBom, patternWhitespace, patternIndicator]);

function isWhitespace(LexerState state, int offset = 0) returns boolean
    => state.peek(offset) == " " || state.peek(offset) == "\t";

function isTabInIndent(LexerState state, int upperLimit) returns boolean
    => state.indent > -1 && state.tabInWhitespace > -1 && state.tabInWhitespace <= upperLimit;

function isTagChar(LexerState state) returns boolean
    => matchPattern(state, [patternUri, patternWord, "%"], ["!", patternFlowIndicator]);

function isMarker(LexerState state, boolean directive) returns boolean {
    string directiveChar = directive ? "-" : ".";
    if state.peek(0) == directiveChar && state.peek(1) == directiveChar && state.peek(2) == directiveChar
        && (isWhitespace(state, 3) || state.peek(3) == ()) {
        state.forward(2);
        return true;
    }
    return false;
}

function isComment(LexerState state) returns boolean
    => state.peek() == "#" && (isWhitespace(state, -1) || state.peek(-1) == ());

function discernPlanarFromIndicator(LexerState state) returns boolean
    => matchPattern(state, [patternPrintable], state.isFlowCollection()
            ? [patternLineBreak, patternBom, patternWhitespace, patternFlowIndicator]
            : [patternLineBreak, patternBom, patternWhitespace], 1);

function getWhitespace(LexerState state) returns string {
    string whitespace = "";

    while state.index < state.line.length() {
        if state.peek() == " " {
            whitespace += " ";
        } else if state.peek() == "\t" {
            state.updateFirstTabIndex();
            whitespace += "\t";
        } else {
            break;
        }
        state.forward();
    }

    return whitespace;
}

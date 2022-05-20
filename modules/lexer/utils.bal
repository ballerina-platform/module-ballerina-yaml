import ballerina/regex;

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
# + inclusionPatterns - Included the regex patterns
# + offset - Offset of the character from the current index. Default = 0  
# + exclusionPatterns - Exclude the regex patterns
# + return - True if the pattern matches
function matchRegexPattern(LexerState state, string|string[] inclusionPatterns, string|string[]? exclusionPatterns = (), int offset = 0) returns boolean {
    // If there is no character to check the pattern, then return false.
    if state.peek(offset) == () {
        return false;
    }

    string inclusionPattern = "[" + concatenateStringArray(inclusionPatterns) + "]";
    string exclusionPattern = "";

    if exclusionPatterns != () {
        exclusionPattern = "(?![" + concatenateStringArray(exclusionPatterns) + "])";
    }
    return regex:matches(<string>state.peek(offset), exclusionPattern + inclusionPattern + "{1}");
}

# Concatenate one or more strings.
#
# + strings - Strings to be concatenated
# + return - Concatenated string
function concatenateStringArray(string[]|string strings) returns string {
    if strings is string {
        return strings;
    }
    string output = "";
    strings.forEach(function(string line) {
        output += line;
    });
    return output;
}

# Check if the tokens adhere to the given string.
#
# + state - Current lexer state
# + chars - Expected string  
# + successToken - Output token if succeed
# + return - If success, returns the token. Else, returns the parsing error.  
function tokensInSequence(LexerState state, string chars, YAMLToken successToken) returns LexerState|LexicalError {
    foreach string char in chars {
        // The expected character is not found
        if state.peek() == () || !checkCharacter(state, char) {
            return generateScanningError(state, string `Expected '${char}' for ${successToken}`);
        }
        state.forward();
    }
    state.lexeme += chars;
    state.index -= 1;
    return state.tokenize(successToken);
}

# Assert the character of the current index
#
# + state - Current lexer state
# + expectedCharacters - Expected characters at the current index  
# + index - Index of the character. If null, takes the lexer's 
# + return - True if the assertion is true. Else, an lexical error
function checkCharacter(LexerState state, string|string[] expectedCharacters, int? index = ()) returns boolean {
    if expectedCharacters is string {
        return expectedCharacters == state.line[index == () ? state.index : index];
    } else if expectedCharacters.indexOf(state.line[index == () ? state.index : index]) == () {
        return false;
    }
    return true;
}

# Returns true if the current character is planar safe.
#
# + state - Current lexer state/
# + return - Return true if a planar safe character is found.
function isPlainSafe(LexerState state) returns boolean
    => matchRegexPattern(state, [PRINTABLE_PATTERN], [LINE_BREAK_PATTERN, BOM_PATTERN, WHITESPACE_PATTERN, INDICATOR_PATTERN]);

public enum ParserOption {
    DEFAULT,
    EXPECT_KEY,
    EXPECT_VALUE
}

public enum DocumentType {
    ANY_DOCUMENT,
    BARE_DOCUMENT,
    DIRECTIVE_DOCUMENT
}

# Parses the TOML document using the lexer
class Parser {
    # Properties for the TOML lines
    private string[] lines;
    private int numLines;
    private int lineIndex = -1;

    # Current token
    private Token currentToken = {token: DUMMY};

    # Previous YAML token
    private YAMLToken prevToken = DUMMY;

    # Used to store the token after peeked.
    # Used later when the checkToken method is invoked.
    private Token tokenBuffer = {token: DUMMY};

    # Lexical analyzer tool for getting the tokens
    Lexer lexer = new ();

    # Flag is set if an empty node is possible to expect
    private boolean explicitKey = false;

    map<string> tagHandles = {};

    # YAML version of the document.
    string? yamlVersion = ();

    private Event[] eventBuffer = [];

    function init(string[] lines) returns ParsingError? {
        self.lines = lines;
        self.numLines = lines.length();
        check self.initLexer();
    }

    # Parse the initialized array of strings
    #
    # + option - To expect the next event to be a key
    # + return - Lexical or parsing error on failure
    public function parse(ParserOption option = DEFAULT, DocumentType docType = BARE_DOCUMENT) returns Event|LexicalError|ParsingError {
        // Empty the event buffer before getting new tokens
        if self.eventBuffer.length() > 0 {
            return self.eventBuffer.shift();
        }

        self.lexer.state = LEXER_START;
        check self.checkToken();

        // Ignore the whitespace at the head
        if self.currentToken.token == SEPARATION_IN_LINE {
            check self.checkToken();
        }

        // Set the next line if the end of line is detected
        if self.currentToken.token == EOL || self.currentToken.token == EMPTY_LINE {
            if self.lineIndex >= self.numLines - 1 {
                return {
                        endType: STREAM
                    };
            }
            check self.initLexer();
            return self.parse(docType = docType);
        }

        // Only directive tokens are allowed in directive document
        if docType == DIRECTIVE_DOCUMENT && !(self.currentToken.token == DIRECTIVE || self.currentToken.token == DIRECTIVE_MARKER) {
            return self.generateError(string `'${self.currentToken.token}' is not allowed in a directive document`);
        }

        match self.currentToken.token {
            DIRECTIVE => {
                // Directives are not allowed in bare documents
                if docType == BARE_DOCUMENT {
                    return self.generateError("Directives are not allowed in a bare document");
                }

                if (self.currentToken.value == "YAML") { // YAML directive
                    check self.yamlDirective();
                    check self.checkToken([SEPARATION_IN_LINE, EOL]);
                } else { // TAG directive
                    check self.tagDirective();
                    check self.checkToken([SEPARATION_IN_LINE, EOL]);
                }
                return check self.parse(docType = DIRECTIVE_DOCUMENT);
            }
            DIRECTIVE_MARKER => {
                return {
                    docVersion: self.yamlVersion == () ? "1.2.2" : <string>self.yamlVersion,
                    tags: self.tagHandles
                };
            }
            DOUBLE_QUOTE_DELIMITER|SINGLE_QUOTE_DELIMITER|PLANAR_CHAR => {
                return self.appendData(option, peeked = true);
            }
            ALIAS => {
                string alias = self.currentToken.value;
                return {
                    alias
                };
            }
            TAG_HANDLE => {
                string tagHandle = self.currentToken.value;

                // Obtain the tag associated with the tag handle
                self.lexer.state = LEXER_TAG_NODE;
                check self.checkToken(TAG);
                string tag = self.currentToken.value;

                // Check if there is a separate 
                check self.separate();

                // Obtain the anchor if there exists
                string? anchor = check self.nodeAnchor();

                return self.appendData(option, {tag, tagHandle, anchor});
            }
            TAG => {
                // Obtain the tag name
                string tag = self.currentToken.value;

                // There must be a separate after the tag
                check self.separate();

                // Obtain the anchor if there exists
                string? anchor = check self.nodeAnchor();

                return self.appendData(option, {tag, anchor});
            }
            ANCHOR => {
                // Obtain the anchor name
                string anchor = self.currentToken.value;

                // Check if there is a separate
                check self.separate();

                // Obtain the tag if there exists
                string? tagHandle;
                string? tag;
                [tagHandle, tag] = check self.nodeTagHandle();

                return self.appendData(option, {tagHandle, tag, anchor});
            }
            MAPPING_VALUE => { // Empty node as the key
                Indentation? indentation = self.currentToken.indentation;
                if indentation == () {
                    return self.generateError("Empty key requires an indentation");
                }
                check self.separate();
                match indentation.change {
                    1 => { // Increase in indent
                        self.eventBuffer.push({value: ()});
                        return {startType: MAPPING};
                    }
                    0 => { // Same indent
                        return {value: ()};
                    }
                    -1 => { // Decrease in indent
                        foreach EventType collectionItem in indentation.collection {
                            self.eventBuffer.push({endType: collectionItem});
                        }
                        return self.eventBuffer.shift();
                    }
                }
            }
            SEPARATOR => { // Empty node as the value in flow mappings
                return {value: ()};
            }
            MAPPING_KEY => { // Explicit key
                self.explicitKey = true;
                return self.appendData(option);
            }
            SEQUENCE_ENTRY => {
                if self.currentToken.indentation == () {
                    return self.generateError("Block sequence must have an indentation");
                }
                match (<Indentation>self.currentToken.indentation).change {
                    1 => { // Indent increase
                        return {startType: SEQUENCE};
                    }
                    0 => { // Sequence entry
                        return self.parse();
                    }
                    -1 => { //Indent decrease 
                        foreach EventType collectionItem in (<Indentation>self.currentToken.indentation).collection {
                            self.eventBuffer.push({endType: collectionItem});
                        }
                        return self.eventBuffer.shift();
                    }
                }
            }
            MAPPING_START => {
                return {startType: MAPPING, flowStyle: true};
            }
            SEQUENCE_START => {
                return {startType: SEQUENCE, flowStyle: true};
            }
            DOCUMENT_MARKER => {
                self.lexer.resetState();
                return {endType: DOCUMENT};
            }
            SEQUENCE_END => {
                return {endType: SEQUENCE};
            }
            MAPPING_END => {
                return {endType: MAPPING};
            }
            LITERAL|FOLDED => {
                self.lexer.state = LEXER_LITERAL;
                string value = check self.blockScalar(self.currentToken.token == FOLDED);
                return {value};
            }
        }
        return self.generateError(string `Invalid token '${self.currentToken.token}' as the first for generating an event`);
    }

    # Check the grammar productions for TAG directives.
    # Update the tag handles map.
    #
    # + return - An error on mismatch.
    private function tagDirective() returns (LexicalError|ParsingError)? {
        // Expect a separate in line
        check self.checkToken(SEPARATION_IN_LINE);

        // Expect a tag handle
        self.lexer.state = LEXER_TAG_HANDLE;
        check self.checkToken(TAG_HANDLE);
        string tagHandle = self.currentToken.value;
        check self.checkToken(SEPARATION_IN_LINE);

        // Expect a tag prefix
        self.lexer.state = LEXER_TAG_PREFIX;
        check self.checkToken(TAG_PREFIX);
        string tagPrefix = self.currentToken.value;

        if (self.tagHandles.hasKey(tagHandle)) {
            return self.generateError(check self.formatErrorMessage(2, value = tagHandle));
        }
        self.tagHandles[tagHandle] = tagPrefix;
    }

    # Check the grammar productions for YAML directives.
    # Update the yamlVersion of the document.
    #
    # + return - An error on mismatch.
    private function yamlDirective() returns LexicalError|ParsingError|() {
        // Expect a separate in line.
        check self.checkToken(SEPARATION_IN_LINE);

        self.lexer.state = LEXER_DIRECTIVE;

        // Expect yaml version
        check self.checkToken(DECIMAL);
        string lexemeBuffer = self.currentToken.value;
        check self.checkToken(DOT);
        lexemeBuffer += ".";
        check self.checkToken(DECIMAL);
        lexemeBuffer += self.currentToken.value;

        // Update the version
        if (self.yamlVersion is null) {
            self.yamlVersion = lexemeBuffer;
            return;
        }

        return self.generateError(check self.formatErrorMessage(2, value = "%YAML"));
    }

    private function doubleQuoteScalar() returns LexicalError|ParsingError|string {
        self.lexer.state = LEXER_DOUBLE_QUOTE;
        string lexemeBuffer = "";
        boolean isFirstLine = true;
        boolean emptyLine = false;
        boolean escaped = false;

        check self.checkToken();

        // Iterate the content until the delimiter is found
        while (self.currentToken.token != DOUBLE_QUOTE_DELIMITER) {
            match self.currentToken.token {
                DOUBLE_QUOTE_CHAR => { // Regular double quoted string char
                    string lexeme = self.currentToken.value;

                    // Check for double escaped character
                    if lexeme.length() > 0 && lexeme[lexeme.length() - 1] == "\\" {
                        lexeme = lexeme.substring(0, lexeme.length() - 2);
                        escaped = true;
                    }

                    else if !isFirstLine {
                        if escaped {
                            escaped = false;
                        } else { // Trim the white space if not escaped
                            lexemeBuffer = self.trimTailWhitespace(lexemeBuffer);
                        }

                        if emptyLine {
                            emptyLine = false;
                        } else { // Add a white space if there are not preceding empty lines
                            lexemeBuffer += " ";
                        }
                    }

                    lexemeBuffer += lexeme;
                }
                EOL => { // Processing new lines
                    if !escaped { // If not escaped, trim the trailing white spaces
                        lexemeBuffer = self.trimTailWhitespace(lexemeBuffer);
                    }
                    isFirstLine = false;
                    check self.initLexer("Expected to end the multi-line double string");
                }
                EMPTY_LINE => {
                    if isFirstLine { // Whitespace is preserved on the first line
                        lexemeBuffer += self.currentToken.value;
                        isFirstLine = false;
                    } else if escaped { // Whitespace is preserved when escaped
                        lexemeBuffer += self.currentToken.value + "\n";
                    } else { // Whitespace is ignored when line folding
                        lexemeBuffer = self.trimTailWhitespace(lexemeBuffer);
                        lexemeBuffer += "\n";
                    }
                    emptyLine = true;
                    check self.initLexer("Expected to end the multi-line double quoted scalar");
                }
                _ => {
                    return self.generateError(string `Invalid character '${self.currentToken.token}' inside the double quote`);
                }
            }
            check self.checkToken();
        }

        check self.verifyKey(isFirstLine);
        return lexemeBuffer;
    }

    private function singleQuoteScalar() returns ParsingError|LexicalError|string {
        self.lexer.state = LEXER_SINGLE_QUOTE;
        string lexemeBuffer = "";
        boolean isFirstLine = true;
        boolean emptyLine = false;

        check self.checkToken();

        // Iterate the content until the delimiter is found
        while self.currentToken.token != SINGLE_QUOTE_DELIMITER {
            match self.currentToken.token {
                SINGLE_QUOTE_CHAR => {
                    string lexeme = self.currentToken.value;

                    if isFirstLine {
                        lexemeBuffer += lexeme;
                    } else {
                        if emptyLine {
                            emptyLine = false;
                        } else { // Add a white space if there are not preceding empty lines
                            lexemeBuffer += " ";
                        }
                        lexemeBuffer += self.trimHeadWhitespace(lexeme);
                    }
                }
                EOL => {
                    // Trim trailing white spaces
                    lexemeBuffer = self.trimTailWhitespace(lexemeBuffer);
                    isFirstLine = false;
                    check self.initLexer("Expected to end the multi-line double string");
                }
                EMPTY_LINE => {
                    if isFirstLine { // Whitespace is preserved on the first line
                        lexemeBuffer += self.currentToken.value;
                        isFirstLine = false;
                    } else { // Whitespace is ignored when line folding
                        lexemeBuffer = self.trimTailWhitespace(lexemeBuffer);
                        lexemeBuffer += "\n";
                    }
                    emptyLine = true;
                    check self.initLexer("Expected to end the multi-line double quoted scalar");
                }
                _ => {
                    return self.generateError("Expected to end the multi-line single quoted scalar");
                }
            }
            check self.checkToken();
        }

        check self.verifyKey(isFirstLine);
        return lexemeBuffer;
    }

    private function verifyKey(boolean isFirstLine) returns LexicalError|ParsingError|() {
        if self.explicitKey {
            return;
        }
        self.lexer.state = LEXER_START;
        check self.checkToken(peek = true);
        if self.tokenBuffer.token == MAPPING_VALUE && !isFirstLine {
            return self.generateError("Single-quoted keys cannot span multiple lines");
        }
    }

    private function planarScalar() returns ParsingError|LexicalError|string {
        // Process the first planar char
        string lexemeBuffer = self.currentToken.value;
        boolean emptyLine = false;
        boolean isFirstLine = true;

        check self.checkToken(peek = true);

        // Iterate the content until an invalid token is found
        while true {
            match self.tokenBuffer.token {
                PLANAR_CHAR => {
                    if self.tokenBuffer.indentation != () {
                        break;
                    }
                    check self.checkToken();
                    if emptyLine {
                        emptyLine = false;
                    } else { // Add a whitespace if there are no preceding empty lines
                        lexemeBuffer += " ";
                    }
                    lexemeBuffer += self.currentToken.value;
                }
                EOL => {
                    check self.checkToken();
                    isFirstLine = false;

                    // Terminate at the end of the line
                    if self.lineIndex == self.numLines - 1 {
                        break;
                    }
                    check self.initLexer("");
                }
                EMPTY_LINE => {
                    lexemeBuffer += "\n";
                    emptyLine = true;
                    check self.checkToken();
                    // Terminate at the end of the line
                    if self.lineIndex == self.numLines - 1 {
                        break;
                    }
                    check self.initLexer("");
                }
                SEPARATION_IN_LINE => {
                    check self.checkToken();
                    // Continue to scan planar char if the white space at the EOL
                    check self.checkToken(peek = true);
                    if self.tokenBuffer.token == MAPPING_VALUE {
                        break;
                    }
                }
                _ => { // Break the character when the token does not belong to planar scalar
                    break;
                }
            }
            check self.checkToken(peek = true);
        }

        check self.verifyKey(isFirstLine);
        return self.trimTailWhitespace(lexemeBuffer);
    }

    private function blockScalar(boolean isFolded) returns ParsingError|LexicalError|string {
        string chompingIndicator = check self.chompingIndicator();

        self.lexer.state = LEXER_LITERAL;
        string lexemeBuffer = "";
        string newLineBuffer = "";
        boolean isFirstLine = true;
        boolean prevTokenIndented = false;

        check self.checkToken(peek = true);

        while true {
            match self.tokenBuffer.token {
                PRINTABLE_CHAR => {
                    if !isFirstLine {
                        string suffixChar = "\n";
                        if isFolded && prevTokenIndented && self.tokenBuffer.value[0] != " " {
                            suffixChar = newLineBuffer.length() == 0 ? " " : "";
                        }
                        lexemeBuffer += newLineBuffer + suffixChar;
                        newLineBuffer = "";
                    }

                    lexemeBuffer += self.tokenBuffer.value;
                    prevTokenIndented = self.tokenBuffer.value[0] != " ";
                    isFirstLine = false;
                }
                EOL => {
                    // Terminate at the end of the line
                    if self.lineIndex == self.numLines - 1 {
                        break;
                    }
                    check self.initLexer();
                }
                EMPTY_LINE => {
                    if !isFirstLine {
                        newLineBuffer += "\n";
                    }
                    if self.lineIndex == self.numLines - 1 {
                        break;
                    }
                    check self.initLexer();
                    isFirstLine = false;
                }
                TRAILING_COMMENT => {
                    self.lexer.trailingComment = true;
                    // Terminate at the end of the line
                    if self.lineIndex == self.numLines - 1 {
                        break;
                    }
                    check self.initLexer();
                    check self.checkToken();
                    check self.checkToken(peek = true);

                    // Ignore the tokens inside trailing comments
                    while self.tokenBuffer.token == EOL || self.tokenBuffer.token == EMPTY_LINE {
                        // Terminate at the end of the line
                        if self.lineIndex == self.numLines - 1 {
                            break;
                        }
                        check self.initLexer();
                        check self.checkToken();
                        check self.checkToken(peek = true);
                    }

                    self.lexer.trailingComment = false;
                    break;
                }
                _ => { // Break the character when the token does not belong to planar scalar
                    break;
                }
            }
            check self.checkToken();
            check self.checkToken(peek = true);
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

    private function chompingIndicator() returns string|LexicalError|ParsingError {
        self.lexer.state = LEXER_BLOCK_HEADER;
        check self.checkToken();

        // Scan for block-header
        match self.currentToken.token {
            CHOMPING_INDICATOR => { // Strip and keep chomping indicators
                string chompingIndicator = self.currentToken.value;
                check self.checkToken(EOL);
                check self.initLexer();
                return chompingIndicator;
            }
            EOL => { // Clip chomping indicator
                check self.initLexer();
                return "=";
            }
            _ => { // Any other characters are not allowed
                return self.generateError(check self.formatErrorMessage(1, CHOMPING_INDICATOR, self.currentToken.token));
            }
        }
    }

    private function nodeTagHandle() returns [string?, string?]|ParsingError|LexicalError {
        string? tag = ();
        string? tagHandle = ();
        match self.tokenBuffer.token {
            TAG => {
                check self.checkToken();
                tag = self.currentToken.value;
                check self.separate();
            }
            TAG_HANDLE => {
                check self.checkToken();
                tagHandle = self.currentToken.value;

                self.lexer.state = LEXER_TAG_NODE;
                check self.checkToken(TAG);
                tag = self.currentToken.value;
                check self.separate();
            }
        }

        return [tagHandle, tag];
    }

    private function nodeAnchor() returns string?|LexicalError|ParsingError {
        string? anchor = ();
        if self.tokenBuffer.token == ANCHOR {
            check self.checkToken();
            anchor = self.currentToken.value;
            check self.separate();
        }
        return anchor;
    }

    private function nodeProperties() returns [string?, string?, string?]|LexicalError|ParsingError {
        string? tagHandle = ();
        string? tag = ();
        string? anchor = ();

        match self.tokenBuffer.token {
            TAG|TAG_HANDLE => {
                [tag, tagHandle] = check self.nodeTagHandle();
                anchor = check self.nodeAnchor();
            }
            ANCHOR => {
                anchor = check self.nodeAnchor();
                [tag, tagHandle] = check self.nodeTagHandle();
            }
        }

        return [tagHandle, tag, anchor];
    }

    private function appendData(ParserOption option, map<json> tagStructure = {}, boolean peeked = false) returns Event|LexicalError|ParsingError {
        Indentation? indentation = ();
        if self.explicitKey {
            indentation = self.currentToken.indentation;
            check self.separate(true);
        }

        string|EventType? value = check self.content(peeked);
        Event? buffer = ();

        if !self.explicitKey {
            indentation = self.currentToken.indentation;
        }

        self.explicitKey = false;

        // Check if the current node is a key
        boolean isJsonKey = self.lexer.isJsonKey;

        // Ignore the whitespace and lines if there is any
        check self.separate(true);
        check self.checkToken(peek = true);

        // Check if the next token is a mapping value or    
        if self.tokenBuffer.token == MAPPING_VALUE || self.tokenBuffer.token == SEPARATOR {
            check self.checkToken();
        }

        // If there are no whitespace, and the current token is ':'
        if self.currentToken.token == MAPPING_VALUE {
            self.lexer.isJsonKey = false;
            check self.separate(isJsonKey, true);
            if option == EXPECT_VALUE {
                buffer = {value: ()};
            }
        }

        // If there ano no whitespace, and the current token is ","
        if self.currentToken.token == SEPARATOR {
            check self.separate(true);
            if option == EXPECT_KEY {
                self.eventBuffer.push({value: ()});
            }
        }

        if indentation is Indentation {
            match indentation.change {
                1 => { // Increased
                    // Block sequence
                    if value is SEQUENCE {
                        return self.constructEvent(tagStructure, {startType: indentation.collection.pop()});
                    }
                    // Block mapping
                    self.eventBuffer.push({value});
                    return self.constructEvent(tagStructure, {startType: indentation.collection.pop()});
                }
                -1 => { // Decreased 
                    buffer = {endType: indentation.collection.shift()};
                    foreach EventType collectionItem in indentation.collection {
                        self.eventBuffer.push({endType: collectionItem});
                    }
                }
            }
        }

        Event event = check self.constructEvent(tagStructure, value is EventType ? {startType: value} : {value});

        if buffer == () {
            return event;
        }
        self.eventBuffer.push(event);
        return buffer;
    }

    private function content(boolean peeked) returns string|EventType|LexicalError|ParsingError|() {
        self.lexer.state = self.explicitKey ? LEXER_EXPLICIT_KEY : LEXER_START;

        if !peeked {
            check self.checkToken();
        }

        // Check for flow and block nodes
        match self.currentToken.token {
            SINGLE_QUOTE_DELIMITER => {
                self.lexer.isJsonKey = true;
                return self.singleQuoteScalar();
            }
            DOUBLE_QUOTE_DELIMITER => {
                self.lexer.isJsonKey = true;
                return self.doubleQuoteScalar();
            }
            PLANAR_CHAR => {
                return self.planarScalar();
            }
            SEQUENCE_START|SEQUENCE_ENTRY => {
                return SEQUENCE;
            }
            MAPPING_START => {
                return MAPPING;
            }
            LITERAL|FOLDED => {
                if self.lexer.numOpenedFlowCollections > 0 {
                    return self.generateError("Cannot have a block node inside a flow node");
                }
                return self.blockScalar(self.currentToken.token == FOLDED);
            }
        }

        // Check for empty nodes with explicit keys
        if self.explicitKey {
            match self.currentToken.token {
                MAPPING_VALUE => {
                    return;
                }
                SEPARATOR => {
                    self.eventBuffer.push({value: ()});
                    return;
                }
                MAPPING_END => {
                    self.eventBuffer.push({value: ()});
                    self.eventBuffer.push({endType: MAPPING});
                    return;
                }
                EOL => { // Only the mapping key
                    self.eventBuffer.push({value: ()});
                    return;
                }
            }
        }

        return self.generateError(check self.formatErrorMessage(1, "<data-node>", self.prevToken));
    }

    private function separate(boolean optional = false, boolean allowEmptyNode = false) returns ()|LexicalError|ParsingError {
        self.lexer.state = LEXER_START;
        check self.checkToken(peek = true);

        // If separate is optional, skip the check when either EOL or separate-in-line is not detected.
        if optional && !(self.tokenBuffer.token == EOL || self.tokenBuffer.token == SEPARATION_IN_LINE) {
            return;
        }

        // Consider the separate for the latter contexts
        check self.checkToken();

        if self.currentToken.token == SEPARATION_IN_LINE {
            // Check for s-b comment
            check self.checkToken(peek = true);
            if self.tokenBuffer.token != EOL {
                return;
            }
            check self.checkToken();
        }

        // For the rest of the contexts, check either separation in line or comment lines
        while self.currentToken.token == EOL || self.currentToken.token == EMPTY_LINE {
            ParsingError? err = self.initLexer();
            if err is ParsingError {
                return optional || allowEmptyNode ? () : err;
            }
            check self.checkToken(peek = true);

            //TODO: account flow-line prefix
            match self.tokenBuffer.token {
                EOL|EMPTY_LINE => { // Check for multi-lines
                    check self.checkToken();
                }
                SEPARATION_IN_LINE => { // Check for l-comment
                    check self.checkToken();
                    check self.checkToken(peek = true);
                    if self.tokenBuffer.token != EOL {
                        return;
                    }
                    check self.checkToken();
                }
                _ => {
                    return;
                }
            }
        }

        return self.generateError(check self.formatErrorMessage(1, [EOL, SEPARATION_IN_LINE], self.currentToken.token));
    }

    private function constructEvent(map<json> m1, map<json>? m2 = ()) returns Event|ParsingError {
        map<json> returnMap = m1.clone();

        if m2 != () {
            m2.keys().forEach(function(string key) {
                returnMap[key] = m2[key];
            });
        }

        error|Event processedMap = returnMap.cloneWithType(Event);

        return processedMap is Event ? processedMap : self.generateError('error:message(processedMap));
    }

    # Find the first non-space character from tail.
    #
    # + value - String to be trimmed
    # + return - Trimmed string
    private function trimTailWhitespace(string value) returns string {
        int i = value.length() - 1;

        if i < 0 {
            return "";
        }

        while value[i] == " " || value[i] == "\t" {
            if i < 1 {
                break;
            }
            i -= 1;
        }

        return value.substring(0, i + 1);
    }

    private function trimHeadWhitespace(string value) returns string {
        int len = value.length();

        if len < 1 {
            return "";
        }

        int i = 0;
        while value[i] == " " || value == "\t" {
            if i == len - 1 {
                break;
            }
            i += 1;
        }

        return value.substring(i);
    }

    # Assert the next lexer token with the predicted token.
    # If no token is provided, then the next token is retrieved without an error checking.
    # Hence, the error checking must be done explicitly.
    #
    # + expectedTokens - Predicted token or tokens  
    # + customMessage - Error message to be displayed if the expected token not found  
    # + peek - Stores the token in the buffer
    # + return - Parsing error if not found
    private function checkToken(YAMLToken|YAMLToken[] expectedTokens = DUMMY, string customMessage = "", boolean peek = false) returns (LexicalError|ParsingError)? {
        Token token;

        // Obtain a token form the lexer if there is none in the buffer.
        if self.tokenBuffer.token == DUMMY {
            self.prevToken = self.currentToken.token;
            token = check self.lexer.getToken();
        } else {
            token = self.tokenBuffer;
            self.tokenBuffer = {token: DUMMY};
        }

        // Add the token to the tokenBuffer if the peek flag is set.
        if peek {
            self.tokenBuffer = token;
        } else {
            self.currentToken = token;
        }

        // Bypass error handling.
        if (expectedTokens == DUMMY) {
            return;
        }

        // Automatically generates a template error message if there is no custom message.
        string errorMessage = customMessage.length() == 0
                                ? check self.formatErrorMessage(1, expectedTokens, self.prevToken)
                                : customMessage;

        // Generate an error if the expected token differ from the actual token.
        if (expectedTokens is YAMLToken) {
            if (token.token != expectedTokens) {
                return self.generateError(errorMessage);
            }
        } else {
            if (expectedTokens.indexOf(token.token) == ()) {
                return self.generateError(errorMessage);
            }
        }
    }

    # Initialize the lexer with the attributes of a new line.
    #
    # + message - Error message to display when if the initialization fails 
    # + return - An error if it fails to initialize  
    private function initLexer(string message = "Unexpected end of stream") returns ParsingError? {
        self.lineIndex += 1;
        if (self.lineIndex >= self.numLines) {
            return self.generateError(message);
        }
        self.lexer.line = self.lines[self.lineIndex];
        self.lexer.index = 0;
        self.lexer.lineNumber = self.lineIndex;
    }

    # Check errors during type casting to Ballerina types.
    #
    # + value - Value to be type casted.
    # + return - Value as a Ballerina data type  
    private function processTypeCastingError(json|error value) returns json|ParsingError {
        // Check if the type casting has any errors
        if value is error {
            return self.generateError("Invalid value for assignment");
        }

        // Returns the value on success
        return value;
    }

    # Generates a Parsing Error.
    #
    # + message - Error message
    # + return - Constructed Parsing Error message  
    private function generateError(string message) returns ParsingError {
        string text = "Parsing Error at line "
                        + self.lexer.lineNumber.toString()
                        + " index "
                        + self.lexer.index.toString()
                        + ": "
                        + message
                        + ".";
        return error ParsingError(text);
    }

    # Generate a standard error message based on the type.
    #
    # 1 - Expected ${expectedTokens} after ${beforeToken}, but found ${actualToken}
    #
    # 2 - Duplicate key exists for ${value}
    #
    # + messageType - Number of the template message
    # + expectedTokens - Predicted tokens  
    # + beforeToken - Token before the predicted token  
    # + value - Any value name. Commonly used to indicate keys.
    # + return - If success, the generated error message. Else, an error message.
    private function formatErrorMessage(
            int messageType,
            YAMLToken|YAMLToken[]|string expectedTokens = DUMMY,
            YAMLToken|string beforeToken = DUMMY,
            string value = "") returns string|ParsingError {

        match messageType {
            1 => { // Expected ${expectedTokens} after ${beforeToken}, but found ${actualToken}
                if (expectedTokens == DUMMY || beforeToken == DUMMY) {
                    return error("Token parameters cannot be null for this template error message.");
                }
                string expectedTokensMessage;
                if (expectedTokens is YAMLToken[]) { // If multiple tokens
                    string tempMessage = expectedTokens.reduce(function(string message, YAMLToken token) returns string {
                        return message + " '" + token + "' or";
                    }, "");
                    expectedTokensMessage = tempMessage.substring(0, tempMessage.length() - 3);
                } else { // If a single token
                    expectedTokensMessage = " '" + <string>expectedTokens + "'";
                }
                return "Expected" + expectedTokensMessage + " after '" + <string>beforeToken + "', but found '" + self.currentToken.token + "'";
            }

            2 => { // Duplicate key exists for ${value}
                if (value.length() == 0) {
                    return error("Value cannot be empty for this template message");
                }
                return "Duplicate key exists for '" + value + "'";
            }

            _ => {
                return error("Invalid message type number. Enter a value between 1-2");
            }
        }
    }
}

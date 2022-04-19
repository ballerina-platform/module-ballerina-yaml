public class LexerState {
    # Properties to represent current position 
    public int index = 0;
    public int lineNumber = 0;

    # Line to be lexically analyzed
    string line = "";

    # Value of the generated token
    string lexeme = "";

    # Current state of the Lexer
    public Context context = LEXER_START;

    # Minimum indentation imposed by the parent nodes
    // int[] seqIndents = [];
    // int[] mapIndents = [];
    Indent[] indents = [];

    # Minimum indentation required to the current line
    int indent = -1;

    # Additional indent set by the indentation indicator
    int addIndent = 1;

    # Represent the number of opened flow collections  
    int numOpenedFlowCollections = 0;

    # Start index of the scalars with delimiter.
    int delimiterStartIndex = -1;

    # Store the lexeme if it will be scanned again by the next token
    string lexemeBuffer = "";

    # Flag is enabled after a JSON key is detected.
    # Used to generate mapping value even when it is possible to generate a planar scalar.
    boolean isJsonKey = false;

    # The lexer is currently processing trailing comments when the flag is set.
    boolean trailingComment = false;

    # When flag is set, updates the current indent to the indent of the first line
    boolean captureIndent = false;

    boolean enforceMapping = false;

    # Output TOML token
    YAMLToken token = DUMMY;

    Indentation? indentation = ();

    # Peeks the character succeeding after k indexes. 
    # Returns the character after k spots.
    #
    # + k - Number of characters to peek. Default = 0
    # + return - Character at the peek if not null  
    function peek(int k = 0) returns string? {
        return self.index + k < self.line.length() ? self.line[self.index + k] : ();
    }

    # Increment the index of the column by k indexes
    #
    # + k - Number of indexes to forward. Default = 1
    function forward(int k = 1) {
        if (self.index + k <= self.line.length()) {
            self.index += k;
        }
    }

    # Add the output YAML token to the current state
    #
    # + token - YAML token
    # + return - Generated lexical token  
    function tokenize(YAMLToken token) returns LexerState {
        self.forward();
        self.token = token;
        return self;
    }

    # Obtain the lexer token
    #
    # + return - Lexer token
    public function getToken() returns Token {
        YAMLToken tokenBuffer = self.token;
        self.token = DUMMY;
        string lexemeBuffer = self.lexeme;
        self.lexeme = "";
        Indentation? indentationBuffer = self.indentation;
        self.indentation = ();
        return {
            token: tokenBuffer,
            value: lexemeBuffer,
            indentation: indentationBuffer
        };
    }

    # Reset the current lexer state
    public function resetState() {
        self.addIndent = 1;
        self.captureIndent = false;
        self.delimiterStartIndex = -1;
        self.enforceMapping = false;
        self.indent = -1;
        self.indents = [];
        self.lexeme = "";
        self.context = LEXER_START;
    }
}

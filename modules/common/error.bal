public const string ERR_REASON_INVALID_INDENTATION = "InvalidIndentation";
public const string ERR_REASON_INVALID_SCHEMA = "InvalidSchema";
public const string ERR_REASON_ALIASING_FAIL = "AliasingFail";
public const string ERR_REASON_LEXEME_VIOLATION = "LexemeViolation";
public const string ERR_REASON_GRAMMAR_VIOLATION = "GrammarViolation";

# Represents the error details when reading a YAML document.
#
# + message - Error message
# + line - Line at which the error occurred
# + column - Column at which the error occurred
# + actual - The actual violated yaml string
# + expected - Expected yaml strings for the violated string
public type ReadErrorDetails record {
    string message;
    int line;
    int column;
    json actual;
    json[]? expected = ();
};

# Represents the error details when writing a YAML document.
#
# + message - Error message
# + actual - The actual violated yaml string
# + expected - Expected yaml strings for the violated string
public type WriteErrorDetails record {|
    string message;
    json actual;
    json[]? expected = ();
|};

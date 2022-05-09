public type IndentationError distinct error<ReadErrorDetails>;

public type SchemaError distinct error<ReadErrorDetails>;

public type TypeError distinct error<ReadErrorDetails>;

public type AliasingError distinct error<ReadErrorDetails>;

# Represents the error details when reading a YAML document.
#
# + message - Error message
# + line - Line at which the error occurred
# + column - Column at which the error occurred
# + actual - The actual violated yaml string
# + expected - Expected yaml strings for the violated string
public type ReadErrorDetails record {
    int line;
    int column;
    json actual;
    json[]? expected = ();
    string? context = ();
};

# Represents the error details when writing a YAML document.
#
# + message - Error message
# + actual - The actual violated yaml string
# + expected - Expected yaml strings for the violated string
public type WriteErrorDetails record {|
    json actual;
    json[]? expected = ();
    string? context = ();
|};

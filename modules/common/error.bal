public type IndentationError distinct error<ReadErrorDetails>;

public type ConversionError distinct error;

public type AliasingError distinct error<ReadErrorDetails>;

# Represents the error details when reading a YAML document.
#
# + line - Line at which the error occurred  
# + column - Column at which the error occurred  
# + actual - The actual violated yaml string  
# + expected - Expected yaml strings for the violated string  
# + context - Context in which the error occurred
public type ReadErrorDetails record {|
    int line;
    int column;
    json actual;
    json? expected = ();
    string? context = ();
|};

# Represents the error details when writing a YAML document.
#
# + actual - The actual violated yaml string
# + expected - Expected yaml strings for the violated string
# + context - Context in which the error occurred
public type WriteErrorDetails record {|
    json actual;
    json? expected = ();
    string? context = ();
|};

# Represents an error caused when failed to alias an anchor.
public type AliasingError distinct error<ReadErrorDetails>;

# Represents an error caused when the indentation is not correct.
public type IndentationError distinct error<ReadErrorDetails>;

# Represents an error caused by the Ballerina lang when converting a data type.
public type ConversionError distinct error;

# Represents the error details when reading a YAML document.
#
# + line - Line at which the error occurred  
# + column - Column at which the error occurred  
# + actual - The erroneous YAML content
# + expected - Expected YAML content for the violated string  
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
# + actual - The erroneous YAML content
# + expected - Expected YAML content for the violated structure
# + context - Context in which the error occurred
public type WriteErrorDetails record {|
    json actual;
    json? expected = ();
    string? context = ();
|};

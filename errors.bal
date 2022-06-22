import yaml.common;
import yaml.serializer;
import yaml.emitter;
import yaml.composer;
import yaml.lexer;
import yaml.parser;
import ballerina/io;
import ballerina/file;
import yaml.schema;

# Represents the generic error type for the YAML package.
public type Error ComposingError|SerializingError|EmittingError|FileError;

// Level 1
# Represents an error caused when failed to access the file.
public type FileError distinct (io:Error|file:Error);

# Represents an error caused during the composing.
public type ComposingError composer:ComposingError;

# Represents an error caused during the serializing.
public type SerializingError serializer:SerializingError;

# Represents an error caused during the emitting.
public type EmittingError emitter:EmittingError;

# Represents an error caused regarding YAML schema.
public type SchemaError schema:SchemaError;

// Level 2
# Represents an error caused during the parsing.
public type ParsingError parser:ParsingError;

// Level 3
# Represents an error caused during the lexical analyzing.
public type LexicalError lexer:LexicalError;

// Level 4
# Represents an error caused when failed to alias an anchor.
public type AliasingError common:AliasingError;

# Represents an error caused when the indentation is not correct.
public type IndentationError common:IndentationError;

# Represents an error caused by the Ballerina lang when converting a data type.
public type ConversionError common:ConversionError;

# Represents an error caused for an invalid compose.
public type ComposeError composer:ComposeError;

# Represents an error caused for an invalid grammar production.
public type GrammarError parser:GrammarError;

# Represents an error that is generated when an invalid character for a lexeme is detected.
public type ScanningError lexer:ScanningError;

# Represents an error caused when constructing a Ballerina data type.
public type ConstructionError schema:ConstructionError;

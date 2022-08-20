# Represents an error caused by the lexical analyzer
type LexicalError distinct error;

# Represents an error caused by parser
type ParsingError distinct error;

# Represents an error caused by composer
type ComposingError distinct error;

# Represents an error caused by serializer
type SerializingError distinct error;

# Represents an error caused by emitter
type EmittingError distinct error;
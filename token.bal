type Token record {|
    YAMLToken token;
    string value = "";
    Indentation? indentation = ();
|};

# Represents indentation change caused by block scalars.
#
# + collection - List of opened or closed collections.
# + change - +1 indent increased, -1 indent decreased, 0 indent has not changed.
type Indentation record {|
    EventType[] collection;
    IndentChange change;
|};

type IndentChange -1|0|1;

enum YAMLToken {
    BOM,
    SEQUENCE_ENTRY = "-",
    MAPPING_KEY = "?",
    MAPPING_VALUE = ":",
    SEPARATOR = ",",
    SEQUENCE_START = "[",
    SEQUENCE_END = "]",
    MAPPING_START = "{",
    MAPPING_END = "}",
    KEY_TOKEN,
    VALUE_TOKEN,
    BLOCK_ENTRY,
    FLOW_ENTRY,
    DIRECTIVE = "%",
    ALIAS = "*",
    ANCHOR = "&",
    TAG_HANDLE = "<tag-handle>",
    TAG_PREFIX = "<tag-prefix>",
    TAG = "<tag>",
    DOT = ".",
    SCALAR = "<scalar>",
    LITERAL = "|",
    FOLDED = ">",
    DECIMAL = "<decimal-integer>",
    SEPARATION_IN_LINE = "<separation-in-line>",
    LINE_BREAK = "<break>",
    DIRECTIVE_MARKER = "---",
    DOCUMENT_MARKER = "...",
    DOUBLE_QUOTE_DELIMITER = "\"",
    DOUBLE_QUOTE_CHAR,
    SINGLE_QUOTE_DELIMITER = "'",
    SINGLE_QUOTE_CHAR,
    PLANAR_CHAR,
    PRINTABLE_CHAR,
    INDENTATION_INDICATOR = "<indentation-indicator>",
    CHOMPING_INDICATOR = "<chomping-indicator>",
    EMPTY_LINE,
    EOL,
    TRAILING_COMMENT = "<trailing-comment>",
    DUMMY
}

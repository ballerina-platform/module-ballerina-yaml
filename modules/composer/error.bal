import yaml.parser;
import yaml.lexer;
import yaml.common;
import yaml.schema;

# Represents an error caused during the composing.
public type ComposingError ComposeError|parser:ParsingError|lexer:LexicalError|
    schema:SchemaError|common:AliasingError;

# Represents an error caused for an invalid compose.
public type ComposeError distinct error<common:ReadErrorDetails>;

# Generate an error message based on the template,
# "Expected '${expectedEvent}' before '-${actualEvent}'"
#
# + state - Current composer state  
# + actualEvent - Obtained invalid event
# + expectedEvent - Next expected event of the stream
# + return - Formatted error message
function generateExpectedEndEventError(ComposerState state,
    string actualEvent, string expectedEvent) returns ComposeError =>
        generateComposeError(state, common:generateExpectedEndEventErrorMessage(actualEvent, expectedEvent),
            actualEvent, expectedEvent);

# Generate an error message based on the template,
# Expected '${expectedKind}' kind for the '${tag}' tag but found '${actualKind}'
#
# + state - Current parser state  
# + actualKind - Actual core schema kind of the data  
# + expectedKind - Expected core schema kind of the data
# + tag - Tag of the data
# + return - Formatted error message
function generateExpectedKindError(ComposerState state, string actualKind, string expectedKind, string tag)
    returns ComposeError => generateComposeError(
        state,
        string `Expected '${expectedKind}' kind for the '${tag}' tag but found '${actualKind}'`,
        actualKind,
        expectedKind);

function generateAliasingError(ComposerState state, string message, common:Event actualEvent)
    returns common:AliasingError =>
        error(
            message,
            line = state.parserState.getLineNumber(),
            column = state.parserState.getIndex(),
            actual = actualEvent
        );

function generateComposeError(ComposerState state, string message, json actualEvent, json? expectedEvent = ()) returns ComposeError =>
    error(
        message,
        line = state.parserState.getLineNumber(),
        column = state.parserState.getIndex(),
        actual = actualEvent,
        expected = expectedEvent
    );


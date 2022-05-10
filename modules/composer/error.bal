import yaml.parser;
import yaml.lexer;
import yaml.common;
import yaml.schema;

# Represents an error caused during the composing.
public type ComposingError ComposeError|parser:ParsingError|lexer:LexicalError|
    schema:SchemaError|common:AliasingError;

# Represents an error caused for an invalid compose.
public type ComposeError distinct error<common:ReadErrorDetails>;

# # Generate an error message based on the template,
# "Expected ${expectedTokens} after ${beforeToken}, but found ${actualToken}"
#
# + state - Current composer state  
# + actualEndEvent - Obtained invalid event
# + expectedEndEvent - Next expected event of the stream
# + return - Formatted error message
function generateExpectedEndEventError(ComposerState state,
    common:EndEvent actualEndEvent, common:EndEvent expectedEndEvent) returns ComposeError =>
        generateComposeError(state, common:generateExpectedEndEventErrorMessage(actualEndEvent, expectedEndEvent),
            actualEndEvent, expectedEndEvent);

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


import yaml.common;

# Represents an error caused during the emitting.
public type EmittingError distinct error<common:WriteErrorDetails>;

# Generate an error message based on the template,
# "Expected '${expectedEvent}' before '-${actualEvent}'"
#
# + actualEvent - Obtained invalid event
# + expectedEvent - Next expected event of the stream
# + return - Formatted error message
function generateExpectedEndEventError(string actualEvent, string expectedEvent) returns EmittingError =>
    generateEmittingError(common:generateExpectedEndEventErrorMessage(actualEvent, expectedEvent),
        actualEvent, expectedEvent);

function generateEmittingError(string message, json actualValue, json? expectedValue = ())
    returns EmittingError =>
        error(
            message,
            actual = actualValue,
            expected = expectedValue
        );

import yaml.common;

# Represents an error caused during the emitting.
public type EmittingError distinct error<common:WriteErrorDetails>;

# # Generate an error message based on the template,
# "Expected ${expectedTokens} after ${beforeToken}, but found ${actualToken}"
#
# + actualEndEvent - Obtained invalid event  
# + expectedEndEvent - Next expected event of the stream
# + return - Formatted error message
function generateExpectedEndEventError(
    common:EndEvent actualEndEvent, common:EndEvent expectedEndEvent) returns EmittingError =>
        generateEmittingError(common:generateExpectedEndEventErrorMessage(actualEndEvent, expectedEndEvent),
            actualEndEvent, expectedEndEvent);

function generateEmittingError(string message, common:Event actualValue, common:Event? expectedValue = ())
    returns EmittingError =>
        error(
            message,
            actual = actualValue,
            expected = expectedValue
        );

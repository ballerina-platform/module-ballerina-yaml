public function generateConversionError(string message) returns ConversionError =>
    error(message);

# Check errors during type casting to Ballerina types.
#
# + value - Value to be type casted.
# + return - Value as a Ballerina data type  
public function processTypeCastingError(json|error value) returns json|ConversionError {
    // Check if the type casting has any errors
    if value is error {
        return generateConversionError('error:message(value));
    }

    // Returns the value on success
    return value;
}

# Generate the string error message of the template,
# "Expected ${expectedTokens} after ${beforeToken}, but found ${actualToken}"
# 
# + actualEndEvent - Obtained invalid event
# + expectedEndEvent - Next expected event of the stream
# + return - Formatted error message
public function generateExpectedEndEventErrorMessage(EndEvent actualEndEvent, EndEvent expectedEndEvent)
    returns string {
    string actualEvent = "-" + actualEndEvent.endType;
    string expectedEvent = "-" + expectedEndEvent.endType;
    return string `Expected '${expectedEvent}' before '-${actualEvent}'`;
}

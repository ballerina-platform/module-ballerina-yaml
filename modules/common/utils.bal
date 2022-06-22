# Generate an error for conversion fault between Ballerina and YAML.
#
# + message - Cause of the error message
# + return - Formatted error message
public function generateConversionError(string message) returns ConversionError => error(message);

# Check errors during type casting to Ballerina types.
#
# + value - Value to be type casted.
# + return - Value as a Ballerina data type  
public function processTypeCastingError(json|error value) returns json|ConversionError {
    // Check if the type casting has any errors
    if value is error {
        return generateConversionError(value.message());
    }

    // Returns the value on success
    return value;
}

# Generate the string error message of the template,
# "Expected '${expectedEvent}' before '-${actualEvent}'"
#
# + actualEvent - Obtained invalid event
# + expectedEvent - Next expected event of the stream
# + return - Formatted error message as a string
public function generateExpectedEndEventErrorMessage(string actualEvent, string expectedEvent) returns string
    => string `Expected '${expectedEvent}' before '-${actualEvent}'`;

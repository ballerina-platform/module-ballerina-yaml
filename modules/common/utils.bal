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

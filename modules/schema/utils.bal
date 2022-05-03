import ballerina/regex;

# Validate the construction of the Ballerina data via a regex pattern.
#
# + regexPattern - Regex pattern used for validation
# + data - Data to be converted to the appropriate structure.
# + typeName - Type name to be displayed in the error message.
# + construct - Function to construct the Ballerina data structure.
# + return - Constructed Ballerina data structure.
function constructWithRegex(string regexPattern,
    json data,
    string typeName,
    function (string data) returns json|TypeError construct) returns json|TypeError {

    if regex:matches(data.toString(), regexPattern) {
        return construct(data.toString());
    }
    return generateError(string `Cannot cast '${data.toJsonString()}' to '${typeName}'`);
}

# Check errors during type casting to Ballerina types.
#
# + value - Value to be type casted.
# + return - Value as a Ballerina data type
function processTypeCastingError(json|error value) returns json|TypeError {
    // Check if the type casting has any errors
    if value is error {
        return generateError("Invalid value for assignment");
    }

    // Returns the value on success
    return value;
}

# Simply represent the value as it is as string.
#
# + data - Data to represent
# + return - String value for the json data.
function representAsString(json data) returns string =>
    data.toString();

# Generate a function that confirms the type of the data.
#
# + typeDesc - Type to be asserted with the given data
# + return - Function to validate the data
public function generateIdentityFunction(typedesc<json> typeDesc) returns function (json data) returns boolean {
    return function(json data) returns boolean {
        json|error output = data.ensureType(typeDesc);
        return output == data;
    };
}

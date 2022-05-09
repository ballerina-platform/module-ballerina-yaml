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
    function (string data) returns json|SchemaError construct) returns json|SchemaError {

    if regex:matches(data.toString(), regexPattern) {
        return construct(data.toString());
    }
    return generateError(string `Cannot cast '${data.toJsonString()}' to '${typeName}'`);
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

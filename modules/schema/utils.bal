import ballerina/regex;

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

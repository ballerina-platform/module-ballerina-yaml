function constructSimpleNull(json data) returns json|TypeError =>
    constructWithRegex("null", data, "null", function(string s) returns json|TypeError => ());

function constructSimpleBool(json data) returns json|TypeError =>
    constructWithRegex("true|false", data, "bool",
    function(string s) returns json|TypeError => processTypeCastingError('boolean:fromString(s)));

function constructSimpleInteger(json data) returns json|TypeError =>
    constructWithRegex("-?(0|[1-9][0-9]*)", data, "int",
    function(string s) returns json|TypeError => processTypeCastingError('int:fromString(s)));

function constructSimpleFloat(json data) returns json|TypeError =>
    constructWithRegex("-?(0|[1-9][0-9]*)(\\.[0-9]*)?([eE][-+]?[0-9]+)?", data, "float",
    function(string s) returns json|TypeError => processTypeCastingError('float:fromString(s)));

function constructNull(json data) returns json|TypeError =>
    constructWithRegex("null|Null|NULL|~", data, "null", function(string s) returns json|TypeError => ());

function constructBool(json data) returns json|TypeError =>
    constructWithRegex("true|True|TRUE|false|False|FALSE", data, "bool",
    function(string s) returns json|TypeError => processTypeCastingError('boolean:fromString(s)));

function constructInteger(json data) returns json|TypeError {
    string value = data.toString();

    // Process integers in different base
    if value[0] == "0" {
        match value[1] {
            "o" => { // Cast to an octal integer
                int output = 0;
                int power = 1;
                int length = value.length() - 3;
                foreach int i in 0 ... length {
                    int digit = <int>(check processTypeCastingError('int:fromString(value[length + 2 - i])));
                    if digit > 7 || digit < 1 {
                        return generateError(string `Invalid digit '${digit}' for the octal base`);
                    }
                    output += digit * power;
                    power *= 8;
                }
                return output;
            }
            "x" => { // Cast to a hexadecimal integer
                return processTypeCastingError('int:fromHexString(value.substring((2))));
            }
        }
    }

    // Cast to a decimal integer
    return constructWithRegex("[-+]?[0-9]+", data, "int",
        function(string s) returns json|TypeError => processTypeCastingError('int:fromString(s)));
}

function constructFloat(json data) returns json|TypeError {
    string value = data.toString();

    // Process the float symbols
    match value[0] {
        "." => {
            match value.substring(1) {
                "nan"|"NAN"|"NaN" => { // Cast to not a number
                    return 'float:NaN;
                }
                "inf"|"Inf"|"INF" => { // Cast to infinity
                    return 'float:Infinity;
                }
            }
        }
        "+"|"-" => {
            // Cast to infinity
            if (value.substring(2) == "inf" || value.substring(2) == "Inf" || value.substring(2) == "INF")
                && value[1] == "." {
                return value[0] == "-" ? -'float:Infinity : 'float:Infinity;
            }
        }
    }

    // Cast to float numbers
    return constructWithRegex("[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?", data, "float",
        function(string s) returns json|TypeError => processTypeCastingError('float:fromString(s)));
}


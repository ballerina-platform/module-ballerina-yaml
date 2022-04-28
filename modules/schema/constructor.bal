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

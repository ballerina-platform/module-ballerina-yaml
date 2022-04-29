public enum FailSafeSchema {
    MAPPING,
    SEQUENCE,
    STRING
}

public type YAMLTypeConstructor record {|
    FailSafeSchema kind;
    function (json data) returns json|TypeError construct;
    function (json data) returns boolean identity;
    function (json data) returns string represent;
|};

public readonly & map<string> defaultTagHandles = {
    "!": "!",
    "!!": "tag:yaml.org,2002:"
};

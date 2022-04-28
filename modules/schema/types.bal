public enum FailSafeSchema {
    MAPPING,
    SEQUENCE,
    STRING
}

public type YAMLTypeConstructor record {|
    FailSafeSchema kind;
    function (string data) returns json|TypeError construct;
|};

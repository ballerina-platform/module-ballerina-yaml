public type Event AliasEvent|ScalarEvent|StartEvent|EndEvent;

public type AliasEvent record {|
    string alias;
|};

public type NodeEvent record {|
    string? anchor = ();
    string? tag = ();
|};

public type ScalarEvent record {|
    *NodeEvent;
    string? value;
|};

public type StartEvent record {|
    *NodeEvent;
    Collection startType;
    boolean flowStyle = false;
|};

public type EndEvent record {|
    Collection endType;
|};

public enum Collection {
    STREAM,
    DOCUMENT,
    SEQUENCE,
    MAPPING
}
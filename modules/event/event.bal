public type Event AliasEvent|ScalarEvent|DocumentStartEvent|StartEvent|EndEvent;

public type AliasEvent record {|
    string alias;
|};

public type NodeEvent record {|
    string? anchor = ();
    string? tag = ();
    string? tagHandle  = ();
|};

public type ScalarEvent record {|
    *NodeEvent;
    string? value;
|};

public type DocumentStartEvent record {|
    boolean explicit = false;
    string docVersion;
    map<string> tags;
|};

public type StartEvent record {|
    Collection startType;
    boolean flowStyle = false;
    *NodeEvent;
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
type Event AliasEvent|ScalarEvent|DocumentStartEvent|StartEvent|EndEvent;

type AliasEvent record {|
    string alias;
|};

type NodeEvent record {|
    string? anchor = ();
    string? tag = ();
    string? tagHandle  = ();
|};

type ScalarEvent record {|
    *NodeEvent;
    string? value;
|};

type DocumentStartEvent record {|
    boolean explicit = false;
    string docVersion;
    map<string> tags;
|};

type StartEvent record {|
    EventType startType;
    boolean flowStyle = false;
    *NodeEvent;
|};

type EndEvent record {|
    EventType endType;
|};

enum EventType {
    STREAM,
    DOCUMENT,
    SEQUENCE,
    MAPPING
}
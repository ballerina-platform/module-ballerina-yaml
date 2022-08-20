# General representation of the YAML event.
public type Event AliasEvent|ScalarEvent|StartEvent|EndEvent|DocumentMarkerEvent;

# Represents an event that aliases another event.
#
# + alias - Name of the aliasing anchor
public type AliasEvent record {|
    string alias;
|};

# Represents the common attributes of a node event.
#
# + anchor - Anchor name of the node if exists  
# + tag - Tag of the node if exists
type NodeEvent record {|
    string? anchor = ();
    string? tag = ();
|};

# Represents the attributes of a scalar.
#
# + value - Value of the YAML scalar
public type ScalarEvent record {|
    *NodeEvent;
    string? value;
|};

# Represents the attributes of a YAML collection.
#
# + startType - YAML collection  
# + flowStyle - If set, the event represents the collection explicitly.  
# + implicit - Flag is set, if there is only one mapping
public type StartEvent record {|
    *NodeEvent;
    Collection startType;
    boolean flowStyle = false;
    boolean implicit = false;
|};

# Represents the attributes to terminate the collection.
#
# + endType - YAML collection
public type EndEvent record {|
    Collection endType;
|};

# Represents the attributes of a YAML document marker.
#
# + explicit - If the marker is start of an explicit document
public type DocumentMarkerEvent record {|
    boolean explicit;
|};

public enum Collection {
    STREAM,
    SEQUENCE,
    MAPPING
}

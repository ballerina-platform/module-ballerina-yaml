import yaml.common;

function getEmittedOutput(common:Event[] events,
    map<string> customTagHandles = {},
    int indentationPolicy = 2,
    boolean canonical = false,
    boolean isStream = false) returns string[]|EmittingError {

    EmitterState state = new (events, customTagHandles, indentationPolicy, canonical);
    return emit(state, isStream);
}

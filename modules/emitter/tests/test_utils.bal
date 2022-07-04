import yaml.common;

function getEmittedOutput(common:Event[] events,
    map<string> customTagSchema = {},
    int indentationPolicy = 2,
    boolean canonical = false,
    boolean isStream = false) returns string[]|EmittingError
    => emit(events, customTagSchema, indentationPolicy, canonical, isStream);

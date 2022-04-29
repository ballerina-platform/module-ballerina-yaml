public function getJsonSchemaTags() returns map<YAMLTypeConstructor> {
    return {
        "tag:yaml.org,2002:null": {
            kind: STRING,
            construct: constructSimpleNull
        },
        "tag:yaml.org,2002:bool": {
            kind: STRING,
            construct: constructSimpleBool
        },
        "tag:yaml.org,2002:int": {
            kind: STRING,
            construct: constructSimpleInteger
        },
        "tag:yaml.org,2002:float": {
            kind: STRING,
            construct: constructSimpleFloat
        }
    };
}

public function getCoreSchemaTags() returns map<YAMLTypeConstructor> {
    return {
        "tag:yaml.org,2002:null": {
            kind: STRING,
            construct: constructNull
        },
        "tag:yaml.org,2002:bool": {
            kind: STRING,
            construct: constructBool
        },
        "tag:yaml.org,2002:int": {
            kind: STRING,
            construct: constructInteger
        },
        "tag:yaml.org,2002:float": {
            kind: STRING,
            construct: constructFloat
        }
    };
}

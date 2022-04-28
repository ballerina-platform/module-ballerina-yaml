public function getJSONSchemaTags() returns map<YAMLTypeConstructor> {
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
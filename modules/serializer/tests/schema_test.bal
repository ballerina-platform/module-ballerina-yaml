import yaml.common;
import yaml.schema;
import ballerina/test;

type RGB [int, int, int];

function constructRGB(json data) returns json|schema:SchemaError {
    RGB|error value = data.cloneWithType();

    if value is error {
        return error("Invalid shape for RGB.");
    }

    foreach int index in value {
        if index > 255 || index < 0 {
            return error("One RGB value must be between 0-255.");
        }
    }

    return value;
}

type ShapeName "circle"|"rectangle"|"square"|"triangle";

function constructShapeName(json data) returns json|schema:SchemaError {
    ShapeName|error value = data.cloneWithType();

    if value is error {
        return error("Invalid shape for ShapeName.");
    }

    return value;
}

type Shape record {|
    ShapeName name;
    RGB color;
|};

function constructShape(json data) returns json|schema:SchemaError {
    Shape|error value = data.cloneWithType();

    if value is error {
        return error("Invalid shape for Shape record.");
    }

    return value;
}

@test:Config {
    dataProvider: customTagDataGen,
    groups: ["serializer"]
}
function testCustomTag(json testingInput, common:StartEvent|common:ScalarEvent expectedEvent, 
    schema:YAMLTypeConstructor typeConstructor) returns error? {
        
    map<schema:YAMLTypeConstructor> tagSchema = schema:getJsonSchemaTags();
    tagSchema[<string>expectedEvent.tag] = typeConstructor;

    common:Event[] events = check getSerializedEvents(testingInput, tagSchema = tagSchema);
    test:assertEquals(events[0], expectedEvent);
}

function customTagDataGen() returns map<[json, common:StartEvent|common:ScalarEvent, schema:YAMLTypeConstructor]> {
    return {
        "custom scalar": [
            <ShapeName>"rectangle",
            {value: "rectangle", tag: "!name"},
            {
                kind: schema:STRING,
                construct: constructShapeName,
                identity: schema:generateIdentityFunction(ShapeName),
                represent: function(json data) returns string => data.toString()
            }
        ],
        "custom sequence": [
            <RGB>[123, 12, 32],
            {startType: common:SEQUENCE, tag: "!rgb"},
            {
                kind: schema:SEQUENCE,
                construct: constructRGB,
                identity: schema:generateIdentityFunction(RGB),
                represent: function(json data) returns string => data.toString()
            }
        ],
        "custom mapping": [
            <Shape>{name: "circle", color: [255, 255, 0]},
            {startType: common:MAPPING, tag: "!shape"},
            {
                kind: schema:MAPPING,
                construct: constructShape,
                identity: schema:generateIdentityFunction(Shape),
                represent: function(json data) returns string => data.toString()
            }
        ]
    };
}

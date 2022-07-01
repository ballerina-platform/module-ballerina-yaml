import yaml.common;
import yaml.schema;
import ballerina/test;

type ShapeName "circle"|"rectangle"|"square"|"triangle";

type RGB [int, int, int];

type Shape record {|
    ShapeName name;
    RGB color;
|};

function (json data) returns boolean identifyShapeName = schema:generateIdentityFunction(ShapeName);
function (json data) returns boolean identifyRGB = schema:generateIdentityFunction(RGB);
function (json data) returns boolean identifyShape = schema:generateIdentityFunction(Shape);
map<function (json data) returns json|schema:SchemaError> representArr = {
    "str": function(json data) returns json|schema:SchemaError => data.toString(),
    "seq": function(json data) returns json|schema:SchemaError => {rgb: data},
    "map": function(json data) returns json|schema:SchemaError => [data]
};

function constructShapeName(json data) returns json|schema:SchemaError {
    ShapeName|error value = data.cloneWithType();

    if value is error {
        return error("Invalid shape for ShapeName.");
    }

    return value;
}

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
        "ballerina string to yaml string": [
            <ShapeName>"rectangle",
            {value: "rectangle", tag: "!name"},
            {
                kind: schema:STRING,
                construct: constructShapeName,
                identity: identifyShapeName,
                represent: function(json data) returns json => data.toString()
            }
        ],
        "ballerina string to yaml sequence": [
            <ShapeName>"rectangle",
            {startType: common:SEQUENCE, tag: "!name"},
            {
                kind: schema:SEQUENCE,
                construct: constructShapeName,
                identity: identifyShapeName,
                represent: function(json data) returns json => [data]
            }
        ],
        "ballerina string to yaml mapping": [
            <ShapeName>"rectangle",
            {startType: common:MAPPING, tag: "!name"},
            {
                kind: schema:MAPPING,
                construct: constructShapeName,
                identity: identifyShapeName,
                represent: function(json data) returns json => {shapeName: data}
            }
        ],
        "ballerina sequence to yaml string": [
            <RGB>[123, 12, 32],
            {value: "(123, 12, 32)", tag: "!rgb"},
            {
                kind: schema:STRING,
                construct: constructRGB,
                identity: identifyRGB,
                represent: function(json j) returns json|schema:SchemaError {
                    RGB|error rgb = j.ensureType();
                    if rgb is error {
                        return error(rgb.message());
                    }
                    return string `(${rgb[0]}, ${rgb[1]}, ${rgb[2]})`;
                }
            }
        ],
        "ballerina sequence to yaml sequence": [
            <RGB>[123, 12, 32],
            {startType: common:SEQUENCE, tag: "!rgb"},
            {
                kind: schema:SEQUENCE,
                construct: constructRGB,
                identity: identifyRGB,
                represent: function(json data) returns json => data
            }
        ],
        "ballerina sequence to yaml mapping": [
            <RGB>[123, 12, 32],
            {startType: common:MAPPING, tag: "!rgb"},
            {
                kind: schema:MAPPING,
                construct: constructRGB,
                identity: identifyRGB,
                represent: function(json data) returns json => {rgb: data}
            }
        ],
        "ballerina mapping to yaml string": [
            <Shape>{name: "circle", color: [255, 255, 0]},
            {value: "circle#[255,255,0]", tag: "!shape"},
            {
                kind: schema:STRING,
                construct: constructShape,
                identity: identifyShape,
                represent: function(json j) returns json|schema:SchemaError {
                    Shape|error shape = j.ensureType();
                    if shape is error {
                        return error(shape.message());
                    }
                    return string `${shape.name}#${shape.color.toString()}`;
                }
            }
        ],
        "ballerina mapping to yaml sequence": [
            <Shape>{name: "circle", color: [255, 255, 0]},
            {startType: common:SEQUENCE, tag: "!shape"},
            {
                kind: schema:SEQUENCE,
                construct: constructShape,
                identity: identifyShape,
                represent: function(json j) returns json|schema:SchemaError {
                    Shape|error shape = j.ensureType();
                    if shape is error {
                        return error(shape.message());
                    }
                    return [shape.name, shape.color];
                }
            }
        ],
        "ballerina mapping to yaml mapping": [
            <Shape>{name: "circle", color: [255, 255, 0]},
            {startType: common:MAPPING, tag: "!shape"},
            {
                kind: schema:MAPPING,
                construct: constructShape,
                identity: identifyShape,
                represent: function(json data) returns json => data
            }
        ]
    };
}

@test:Config {
    dataProvider: invalidRepresentFunctionDataGen,
    groups: ["serializer"]
}
function testInvalidRepresentFunctionForKind(schema:FailSafeSchema kind, string representArrKey) {
    RGB rgb = [255, 124, 0];

    map<schema:YAMLTypeConstructor> tagSchema = schema:getJsonSchemaTags();
    tagSchema["!rgb"] = {
        kind,
        construct: constructRGB,
        identity: identifyRGB,
        represent: representArr.get(representArrKey)
    };

    common:Event[]|schema:SchemaError events = getSerializedEvents(rgb, tagSchema = tagSchema);
    test:assertTrue(events is schema:SchemaError);
}

function invalidRepresentFunctionDataGen() returns map<[schema:FailSafeSchema, string]> {
    return {
        "represent string for sequence": [schema:SEQUENCE, "str"],
        "represent mapping for sequence": [schema:SEQUENCE, "map"],
        "represent string for mapping": [schema:MAPPING, "str"],
        "represent sequence for mapping": [schema:MAPPING, "seq"]
    };
}

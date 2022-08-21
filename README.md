# Ballerina YAML Parser

![Build](https://github.com/ballerina-platform/module-ballerina-yaml/actions/workflows/ci.yml/badge.svg)

Ballerina YAML parser provides APIs to convert a YAML configuration file to `json`, and vice-versa. The module supports both the functions of read and write either a single YAML document or a YAML stream.

Since the parser is following LL(1) grammar, it follows a non-recursive predictive parsing algorithm which operates in a linear time complexity.

## Compatibility

| Language  | Version                        |
| --------- | ------------------------------ |
| Ballerina | Ballerina 2201.0.0 (Swan Lake) |
| YAML      | 1.2.2                          |

The parser follows the grammar rules particularized in the [YAML specification 1.2.2](https://yaml.org/spec/1.2.2/).

### Parsing a YAML File

The read function allows the user to obtain either a YAML document or an array of YAML stream if the `isStream` flag is set.

```ballerina
// Parsing a YAML document
json|yaml:Error yamlDoc = yaml:readFile("path/to/file.yml");

// Parsing a YAML stream
json|yaml:Error yamlDocs = yaml:readFile("path/to/file.yml", isStream = true);

// Parsing a YAML string 
json|yaml:Error yamlLine = yaml:readString("outer: {inner: value}");
```

The user can either set the `allowAnchorRedefinition` or `allowMapEntryRedefinition` to let the parser overwrite anchors and map entry keys respectively.

### Writing a YAML File

The user can write either a document or a stream using this function.

```ballerina
// Writing a YAML document
check yaml:writeFile("path/to/file.yaml", yamlContent);

// Writing a YAML stream
check yaml:writeFile("path/to/file.yaml", yamlContent, isStream = true);

// Writing a YAML string
json|yaml:Error jsonOutput = yaml:writeString("outer: {inner: value}");
```

By default, the parser attempts to write the YAML scalars in planar style. However, there are some scalars that cause ambiguity against a few control symbols in YAML. In this case to remove the vagueness, the parser will either add  `"` quotes or `'` quotes based on the `useSingleQuotes` flag is set. Further, if the `forceQuotes` flag is set, then all the scalars will be quoted. 

The following options can be set to further format the output YAML file.

| Option                  | Default | Description                                                                                         |
| ----------------------- | ------- | --------------------------------------------------------------------------------------------------- |
| `int indentationPolicy` | `2`     | The number of whitespaces considered to a indent.                                                   |
| `int blockLevel`        | `1`     | The maximum depth level for the block-style collections before the flow-style collections are used. |
| `boolean canonical`     | `false` | If the flag is set, the parser will write the tag along with the node.                              |

## YAML Schema and Supported Data Types

The `Fail Safe Schema` is the most basic schema supported by any YAML document. The corresponding Ballerina data types are listed as shown below.

| YAML Tag | Ballerina Data Type     |
| -------- | ----------------------- |
| !!str    | `ballerina.lang.string` |
| !!seq    | `ballerina.lang.array`  |
| !!map    | `ballerina.lang.map`    |

In addition to the `Fail Safe Schema`, the `JSON Schema` defines the following tags to enable basic JSON support. The `Core Schema` is an extension of the `JSON Schema` that supports the same tags with more human-readable notations.

| YAML Tag | Ballerina Data Type      |
| -------- | ------------------------ |
| !!null   | `()`                     |
| !!bool   | `ballerina.lang.boolean` |
| !!int    | `ballerina.lang.int`     |
| !!float  | `ballerina.lang.float`   |

## Custom YAML Types

A custom tag support can be added to the YAML parser by writing a record of the type `YAMLType`. All the custom YAML tags must be provided as an array to the `yamlTypes` property in the config. The following code segment demonstrates an example of adding a custom tag to the parser.

```ballerina
import ballerina/yaml;

type RGB [int, int, int];

// Validation function to check before constructing the RGB
function constructRGB(json data) returns json|yaml:SchemaError {
    RGB|error value = data.cloneWithType();

    if value is error {
        return error("Invalid shape for RGB");
    }

    foreach int index in value {
        if index > 255 || index < 0 {
            return error("One RGB value must be between 0-255");
        }
    }

    return value;
}

public function main() returns error? {
    yaml:YAMLType rgbType = {
        tag: "!rgb",
        ballerinaType: RGB,
        kind: yaml:SEQUENCE,
        construct: constructRGB,
        represent: function(json data) returns string => data.toString()
    };

    RGB color = [256, 12, 32];
    json balStruct = {color};

    check yaml:writeFile("rgb.yml", balStruct, canonical = true, yamlTypes = [rgbType]);
}
```

The parser considers these custom tags before the default tags when resolving. Thus, the output tag is `!rgb` rather than `!seq`.

```yaml
!!str color: !rgb [!!int 256, !!int 12, !!int 32]
```

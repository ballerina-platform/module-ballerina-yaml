# Ballerina YAML Parser

![Build](https://github.com/nipunayf/module-ballerina-yaml/actions/workflows/ci.yml/badge.svg)

`Ballerina YAML Parser` converts a given YAML file to a Ballerina data structure. 



Initially, import the `nipunayf/yaml` into your Ballerina project.

```Ballerina
import nipunayf/yaml;
```

The module supports both to read and write either a single YAML document or a YAML stream.

## Compatibility

| Language  | Version                        |
| --------- | ------------------------------ |
| Ballerina | Ballerina 2201.0.0 (Swan Lake) |
| YAML      | 1.2.2                          |

The parser follows the grammar rules particularized in the [YAML specification 1.2.2](https://yaml.org/spec/1.2.2/).

### Parsing a YAML File

The read function allows the user to obtain either a YAML document or an array of YAML stream if the `isStream` flag is set.

```Ballerina
// Parsing a YAML document
json|error yamlDoc = check read("path/to/file.yaml", {});

// Parsing a YAML stream
json[]|error yamlDocs = check read("path/to/file.yaml", {}, true);
```

### Writing a YAML File

The user can write either a document or a stream using the write function.

```Ballerina
// Writing a YAML document
check write("path/to/file.yaml", yamlContent, {});

// Writing a YAML stream
check write("path/to/file.yaml", yamlContent, {}, true);
```

By default, the parser attempts to write the YAML scalars in planar style. However, there are some strings that cause ambiguity with some control symbols in YAML. In this case, the parser will add `"` quotes to remove the ambiguity. Further, if the `forceQuotes` flag is set, then all the scalars will be quoted. Additionally, the delimiter can be changed `'` to by enabling the `useSingleQuotes` flag.

The following options can be set to further format the output YAML file.

| Option                  | Default | Description                                                                                                                                  |
| ----------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `int indentationPolicy` | `2`     | The number of whitespaces considered to a indent. An indentation is made once a standard or an array table is defined under the current one. |
| `int blockLevel`        | `1`     | The maximum depth level for the block-style collections before the flow-style collections are used.                                          |
| `boolean canonical`     | `false` | If the flag is set, the parser will write the tag along with the node.                                                                       |

## YAML Schema and Supported Data Types

The `Fail Safe Schema` is the most basic schema which is supported by any YAML document. The corresponding Ballerina data types are listed as shown below.

| YAML Tag | Ballerina Data Type     |
| -------- | ----------------------- |
| !!str    | `ballerina.lang.string` |
| !!seq    | `ballerina.lang.array`  |
| !!map    | `ballerina.lang.map`    |

In addition to the `Fail Safe Schema` the `JSON Schema` maps YAML tags to a Ballerina data types as follows. The `Core Schema` is an extension of the `JSON Schema` that supports the same tags as the latter with more human-readable notations.

| YAML Tag | Ballerina Data Type      |
| -------- | ------------------------ |
| !!null   | `()`                     |
| !!bool   | `ballerina.lang.boolean` |
| !!int    | `ballerina.lang.int`     |
| !!float  | `ballerina.lang.float`   |

## Custom YAML Types

A custom tag support can be added to the YAML parser by writing a record of the type `YAMLType`. All the custom YAML tags must be provided as an array to the `yamlTypes` property in the config.

```Ballerina
import yaml.schema;

type RGB [int, int, int];

# Validation function to check before constructing the RGB
function constructRGB(json data) returns json|schema:TypeError {
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


public function main() returns error?{
    YAMLType rgbType = {
        tag: "!rgb",
        ballerinaType: RGB,
        kind: SEQUENCE,
        construct: constructRGB,
        represent: function(json data) returns string => data.toString()
    };

    RGB color = [256, 12, 32];
    json balStruct = {color};

    check write("rgb.yml", balStruct, {canonical: true, yamlTypes: [rgbType]});
}
```

The parser considers these custom tags before the default tags when resolving. Thus, the output tag is `!rgb` rather than `!seq`.

```yaml
!!str color: !rgb [!!int 256, !!int 12, !!int 32]
```

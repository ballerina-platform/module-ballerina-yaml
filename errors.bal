// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import yaml.common;
import yaml.emitter;
import yaml.composer;
import yaml.lexer;
import yaml.parser;
import ballerina/io;
import ballerina/file;
import yaml.schema;

# Represents the generic error type for the YAML package.
public type Error ComposingError|EmittingError|FileError;

// Level 1
# Represents an error caused when failed to access the file.
public type FileError distinct (io:Error|file:Error);

# Represents an error caused during the composing.
public type ComposingError composer:ComposingError;

# Represents an error caused during the emitting.
public type EmittingError emitter:EmittingError;

# Represents an error caused regarding YAML schema.
public type SchemaError schema:SchemaError;

// Level 2
# Represents an error caused during the parsing.
public type ParsingError parser:ParsingError;

// Level 3
# Represents an error caused during the lexical analyzing.
public type LexicalError lexer:LexicalError;

// Level 4
# Represents an error caused when failed to alias an anchor.
public type AliasingError common:AliasingError;

# Represents an error caused when the indentation is not correct.
public type IndentationError common:IndentationError;

# Represents an error caused by the Ballerina lang when converting a data type.
public type ConversionError common:ConversionError;

# Represents an error caused for an invalid compose.
public type ComposeError composer:ComposeError;

# Represents an error caused for an invalid grammar production.
public type GrammarError parser:GrammarError;

# Represents an error that is generated when an invalid character for a lexeme is detected.
public type ScanningError lexer:ScanningError;

# Represents an error caused when constructing a Ballerina data type.
public type ConstructionError schema:ConstructionError;

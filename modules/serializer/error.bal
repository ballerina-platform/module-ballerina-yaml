import yaml.schema;

# Generate an error message based on the template,
# Error while representing the tag '${tag}'. Expected the return type to be '${kind}'.
#
# + tag - The tag which has the invalid represent function
# + kind - Expected return type of the represent function
# + return - Formatted error message
function generateInvalidRepresentError(string tag, string kind)
    returns schema:SchemaError => error(
        string `Error while representing the tag '${tag}'. Expected the return type to be '${kind}'.`,
        expected = kind);

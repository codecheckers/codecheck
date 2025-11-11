# Validate YAML syntax of a codecheck.yml file

This function checks whether a YAML file has valid syntax that can be
parsed. It does not validate the content or structure against the
CODECHECK specification. Use
[`validate_codecheck_yml`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md)
for full validation.

## Usage

``` r
validate_yaml_syntax(yml_file, stop_on_error = TRUE)
```

## Arguments

- yml_file:

  Path to the YAML file to validate

- stop_on_error:

  If TRUE (default), stop execution with an error message if YAML is
  invalid. If FALSE, return FALSE on invalid YAML instead of stopping.

## Value

Invisibly returns TRUE if YAML is valid. If stop_on_error is FALSE,
returns FALSE on invalid YAML. If stop_on_error is TRUE, stops execution
with an error message.

## Author

Daniel Nüst

## Examples

``` r
if (FALSE) { # \dontrun{
# Validate a codecheck.yml file
validate_yaml_syntax("codecheck.yml")

# Check without stopping on error
is_valid <- validate_yaml_syntax("codecheck.yml", stop_on_error = FALSE)
} # }
```

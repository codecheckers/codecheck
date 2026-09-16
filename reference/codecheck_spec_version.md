# The specification version a \`codecheck.yml\` is validated against

Read from the \`version\` node. A file without one is validated against
the newest specification this package knows, which is what the
specification asks tools to assume.

## Usage

``` r
codecheck_spec_version(configuration)
```

## Arguments

- configuration:

  A parsed \`codecheck.yml\` as a list, or a path to one.

## Value

The version as a string, e.g. \`"2.0"\`.

## See also

\[validate_codecheck_yml_rules()\], \[codecheck_rules()\]

## Examples

``` r
codecheck_spec_version(list(version = "https://codecheck.org.uk/spec/config/1.0/"))
#> [1] "1.0"
codecheck_spec_version(list())
#> [1] "2.0"
```

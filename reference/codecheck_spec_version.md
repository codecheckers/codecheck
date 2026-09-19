# The specification version a \`codecheck.yml\` is validated against

Read from the \`version\` node, including the historical
\`https://codecheck.org.uk/spec/1.0\` form that certificates from 2020
carry.

## Usage

``` r
codecheck_spec_version(configuration, modified = NULL)
```

## Arguments

- configuration:

  A parsed \`codecheck.yml\` as a list, or a path to one.

- modified:

  When the configuration was last changed at its source, as a \`Date\`
  or \`POSIXct\`, used when the file carries no \`check_time\`.

## Value

The version as a string, e.g. \`"2.0"\`.

## Details

A file without a version node is dated instead: the version that was
current when the CODECHECK was performed (\`check_time\`, or
\`modified\`) is used, so a configuration written in 2020 is not judged
against requirements published in 2026. Only a file that cannot be dated
falls back to the newest version, which is what the specification asks
tools to assume. See "Choosing the specification version" in the
register's \`RULES.md\`.

## See also

\[validate_codecheck_yml_rules()\], \[codecheck_rules()\]

## Examples

``` r
codecheck_spec_version(list(version = "https://codecheck.org.uk/spec/config/1.0/"))
#> [1] "1.0"
codecheck_spec_version(list())
#> [1] "2.0"
```

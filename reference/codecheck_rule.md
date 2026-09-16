# One CODECHECK validation rule

One CODECHECK validation rule

## Usage

``` r
codecheck_rule(id, spec_version = codecheck_spec_versions()[1])
```

## Arguments

- id:

  Rule identifier, e.g. \`"CC-CFG-016"\`.

- spec_version:

  Version of the configuration file specification, as a string, e.g.
  \`"2.0"\`. Defaults to the version the register's tooling currently
  targets.

## Value

A one-row data frame, see \[codecheck_rules()\]. Stops if the identifier
is unknown, because a typo in a rule tag should not pass silently.

## See also

\[codecheck_rules()\]

## Examples

``` r
codecheck_rule("CC-CFG-016")
#>            id          name   area severity status
#> 16 CC-CFG-016 paper-present config    error active
#>                                         reference
#> 16 spec/config/2.0#author-and-submission-metadata
#>                           description
#> 16 A root-level paper node is present
```

# The severity of a CODECHECK validation rule

The severity of a CODECHECK validation rule

## Usage

``` r
rule_severity(id, spec_version = codecheck_spec_versions()[1])
```

## Arguments

- id:

  Rule identifier, e.g. \`"CC-CFG-016"\`.

- spec_version:

  Version of the configuration file specification, as a string, e.g.
  \`"2.0"\`. Defaults to the version the register's tooling currently
  targets.

## Value

\`"error"\`, \`"warning"\` or \`"info"\`, see \[codecheck_rules()\] for
what these mean.

## See also

\[codecheck_rules()\]

## Examples

``` r
rule_severity("CC-CFG-016")
#> [1] "error"
rule_severity("CC-CFG-016", spec_version = "1.0")
#> [1] "warning"
```

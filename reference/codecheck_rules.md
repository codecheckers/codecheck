# The CODECHECK validation rules

The checks that CODECHECK tooling applies to a \`codecheck.yml\` file
are maintained as a machine-readable list in the register repository,
one file per version of the configuration file specification, with the
identifier scheme documented in
\<https://github.com/codecheckers/register/blob/master/RULES.md\>. Both
implementations of the rules, this package and the Go bot, tag their
checks with the same identifiers so that the two can be compared
mechanically.

## Usage

``` r
codecheck_rules(spec_version = codecheck_spec_versions()[1])

codecheck_spec_versions()
```

## Arguments

- spec_version:

  Version of the configuration file specification, as a string, e.g.
  \`"2.0"\`. Defaults to the version the register's tooling currently
  targets.

## Value

\`codecheck_rules()\` returns a data frame with one row per rule and the
columns \`id\`, \`name\`, \`area\`, \`severity\`, \`status\`,
\`reference\` and \`description\`, ordered as in the file.

## Details

The rule files are bundled with this package and read from disk, so no
network access is needed. \[update_codecheck_rules()\] refreshes them
from the register, and \[codecheck_rules_provenance()\] reports which
register commit the bundled copies came from and when they were fetched.

The \`severity\` of a rule is a property of the rule, derived from the
RFC 2119 keyword the specification uses: \`error\` for a MUST,
\`warning\` for a SHOULD, \`info\` for a MAY or for advice. It is not
affected by how a check is invoked: the \`strict\` argument of the
validation functions escalates warnings to errors, it never lowers an
error.

## Functions

- `codecheck_spec_versions()`: The specification versions this package
  carries rules for, newest first.

## See also

\[codecheck_rule()\], \[rule_severity()\],
\[codecheck_rules_provenance()\]

## Examples

``` r
rules <- codecheck_rules()
head(rules[, c("id", "name", "severity")])
#>           id                   name severity
#> 1 CC-CFG-001            yaml-parses    error
#> 2 CC-CFG-002      explicit-document    error
#> 3 CC-CFG-003 file-name-and-location    error
#> 4 CC-CFG-004       manifest-present    error
#> 5 CC-CFG-005     manifest-item-file    error
#> 6 CC-CFG-006 manifest-path-relative    error
```

# Validate the register against the CODECHECK rules

Runs the rules about the register as a whole, rather than about one
\`codecheck.yml\`: that certificate identifiers continue their year's
sequence (\`CC-REG-002\`), that every \`Type\` is one of the four venue
types (\`CC-REG-004\`), and that every \`Venue\` is listed in
\`venues.csv\` (\`CC-REG-005\`). Severities come from the rule file, as
for \[validate_codecheck_yml_rules()\]. \[register_check()\] runs this
first.

## Usage

``` r
validate_register_rules(
  register = "register.csv",
  venues_file = "venues.csv",
  spec_version = codecheck_spec_versions()[1],
  strict = FALSE,
  stop_on_error = TRUE,
  quiet = FALSE
)
```

## Arguments

- register:

  The register as a data frame, or a path to \`register.csv\`.

- venues_file:

  Path to \`venues.csv\`. When it does not exist, \`CC-REG-005\` is
  skipped.

- spec_version:

  Specification version whose rule file gives the severities, defaulting
  to the newest.

- strict:

  Escalate warnings to errors. It never works the other way: an error
  stays an error.

- stop_on_error:

  Stop with an error when any rule failed at severity \`error\`. Set to
  \`FALSE\` to get the results back for reporting.

- quiet:

  Do not print the per-rule report.

## Value

Invisibly, a data frame with one row per rule, see
\[validate_codecheck_yml_rules()\].

## See also

\[register_check()\], \[codecheck_rules()\]

## Examples

``` r
if (FALSE) { # \dontrun{
validate_register_rules("register.csv", venues_file = "venues.csv")
} # }
```

# Validate codecheck.yml metadata against an open scholarly database

Validate codecheck.yml metadata against an open scholarly database

## Usage

``` r
validate_codecheck_yml_metadata(
  yml_file = "codecheck.yml",
  strict = FALSE,
  check_orcids = TRUE,
  stop_on_error = TRUE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- strict:

  Logical. If `TRUE`, report warnings as errors.

- check_orcids:

  Logical. If `TRUE` (default), compare author ORCIDs with OpenAlex
  (\`CC-MET-008\`).

- stop_on_error:

  Logical. If `TRUE` (default), stop when a rule failed at severity
  error. Rules at severity warning only ever warn.

## Value

Invisibly returns a list with validation results:

- valid:

  Logical, `FALSE` if any rule failed at severity error or warning

- issues:

  Character vector of the failed rules, in words

- metadata:

  The metadata retrieved from OpenAlex (if available)

- results:

  The per-rule results, see \[validate_codecheck_yml_rules()\]

## Details

Retrieves what OpenAlex knows about the paper's DOI and compares it with
the local codecheck.yml metadata: whether the reference resolves, the
title, the number of authors, their names and their ORCIDs. These are
the rules \`CC-MET-004\` to \`CC-MET-008\`, run through
\[validate_codecheck_yml_rules()\] together with the two rules they
depend on, \`CC-CFG-016\` paper-present and \`CC-CFG-021\`
paper-reference, and reported at the severity the rule file of the
declared specification version gives them.

A record that cannot be retrieved, because the API is unreachable or
rate limited, makes the comparisons skip. It never fails the validation.

Note: For comprehensive validation including ORCID name verification and
codechecker validation, use
[`validate_contents_references()`](http://codecheck.org.uk/codecheck/reference/validate_contents_references.md)
instead.

## See also

\[validate_codecheck_yml_rules()\]

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Validate with warnings only
  result <- validate_codecheck_yml_metadata()

  # Validate with strict error checking
  validate_codecheck_yml_metadata(strict = TRUE)

  # Skip ORCID validation
  validate_codecheck_yml_metadata(check_orcids = FALSE)
} # }
```

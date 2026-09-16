# Validate codecheck.yml metadata against ORCID

Validate codecheck.yml metadata against ORCID

## Usage

``` r
validate_codecheck_yml_orcid(
  yml_file = "codecheck.yml",
  strict = FALSE,
  validate_authors = TRUE,
  validate_codecheckers = TRUE,
  skip_on_auth_error = FALSE,
  stop_on_error = TRUE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- strict:

  Logical. If `TRUE`, report warnings as errors.

- validate_authors:

  Logical. If `TRUE` (default), validate author ORCIDs.

- validate_codecheckers:

  Logical. If `TRUE` (default), validate codecheckers and their ORCIDs.

- skip_on_auth_error:

  Deprecated and without effect: a record that cannot be retrieved is
  always skipped.

- stop_on_error:

  Logical. If `TRUE` (default), stop when a rule failed at severity
  error. Rules at severity warning only ever warn.

## Value

Invisibly returns a list with validation results:

- valid:

  Logical, `FALSE` if any rule failed at severity error or warning

- issues:

  Character vector of the failed rules, in words

- skipped:

  Logical, `TRUE` if at least one ORCID record could not be retrieved

- results:

  The per-rule results, see \[validate_codecheck_yml_rules()\]

## Details

Validates author and codechecker information against the public ORCID
API: that codecheckers are present and named (\`CC-CFG-008\`,
\`CC-CFG-009\`), that every ORCID is well-formed (\`CC-MET-001\`),
resolves (\`CC-MET-002\`), and carries the name given in the
codecheck.yml (\`CC-MET-003\`). The rules are run through
\[validate_codecheck_yml_rules()\] and reported at the severity the rule
file of the declared specification version gives them.

Records are read from the public ORCID API, which needs no token and
reads any record whose name is public. An ORCID record that cannot be
retrieved, because the API is unreachable or rate limited, is skipped.
It never fails the validation.

## See also

\[validate_codecheck_yml_rules()\]

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  result <- validate_codecheck_yml_orcid()

  # Validate with strict error checking
  validate_codecheck_yml_orcid(strict = TRUE)

  # Validate only codecheckers
  validate_codecheck_yml_orcid(validate_authors = FALSE)
} # }
```

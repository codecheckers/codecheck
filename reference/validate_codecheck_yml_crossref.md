# Validate codecheck.yml metadata against CrossRef

Deprecated, and no longer a Crossref lookup: use
\[validate_codecheck_yml_metadata()\], which asks OpenAlex. The returned
list carries the record as \`crossref_metadata\` as well as
\`metadata\`, so code written against the old name keeps working.

## Usage

``` r
validate_codecheck_yml_crossref(
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

Invisibly, what \[validate_codecheck_yml_metadata()\] returns, plus
\`crossref_metadata\`

## See also

\[validate_codecheck_yml_metadata()\]

# How many register persons have a ROR in their ORCID profile

Preparation for register#53, which wants organisation pages built from
the RORs of the register's authors and codecheckers: for every
ORCID-identified person on every certificate, this reports whether their
ORCID profile asserts a ROR-identified affiliation, and whether one of
those was held when the work they are on was published.

## Usage

``` r
register_ror_coverage(
  register_table = NULL,
  register = read.csv("register.csv", as.is = TRUE, comment.char = "#"),
  config = system.file("extdata", "config.R", package = "codecheck")
)
```

## Arguments

- register_table:

  A preprocessed register table with a \`Person\` list column (see
  \`preprocess_register()\`). When \`NULL\` (the default), the register
  is read and preprocessed, so the function can be run in one call from
  a register checkout.

- register:

  The register data frame, used when \`register_table\` is \`NULL\`.

- config:

  Path(s) to the register configuration, sourced when \`register_table\`
  is \`NULL\`.

## Value

A data frame with one row per (certificate, person, role) and the
columns \`Certificate ID\`, \`Person\`, \`Role\`, \`date\`,
\`date_source\`, \`n_affiliations\`, \`has_ror\`, \`has_current_ror\`,
\`ror_at_date\` (a list column) and \`matched_at_date\`. The per-ORCID
affiliation tables are kept in the \`affiliations\` attribute.

## Details

A codechecker's date is the register's check date. An author's is the
paper's publication date from OpenAlex, falling back to the check date
for the certificates without an OpenAlex ID - \`date_source\` says which
was used.

## Examples

``` r
if (FALSE) { # \dontrun{
  # from a checkout of codecheckers/register
  coverage <- register_ror_coverage()
  ror_coverage_summary(coverage)
} # }
```

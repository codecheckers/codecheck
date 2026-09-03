# The RORs a person's ORCID profile asserts

Reads the affiliations on a public ORCID record (employments, educations
and qualifications) and returns the RORs of those the record identifies
with a ROR - the identifiers organisation pages for the register would
be built on (register#53).

## Usage

``` r
orcid_rors(orcid, at = NULL)
```

## Arguments

- orcid:

  An ORCID identifier (NNNN-NNNN-NNNN-NNNX).

- at:

  Optional \`Date\`. When given, only affiliations held at that date are
  considered; when \`NULL\` (the default), only current ones, i.e. those
  the record gives no end date for.

## Value

A character vector of ROR ids (without the \`https://ror.org/\` prefix),
in record order and without duplicates. Empty when the profile asserts
none, or when ORCID could not be reached.

## Examples

``` r
if (FALSE) { # \dontrun{
  orcid_rors("0000-0001-8607-8025")
  orcid_rors("0000-0001-8607-8025", at = as.Date("2019-02-14"))
} # }
```

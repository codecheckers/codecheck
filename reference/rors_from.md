# Filter an affiliation table down to the RORs held at a date

The table-level half of \[orcid_rors()\], so a caller that already has
the affiliations does not look them up again for every certificate.

## Usage

``` r
rors_from(affiliations, at = NULL)
```

## Arguments

- affiliations:

  An affiliation table (see \[get_orcid_affiliations_result()\])

- at:

  A \`Date\`, or \`NULL\` for the current affiliations

## Value

A character vector of ROR ids

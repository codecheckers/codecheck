# Explode the Organisation list column into one row per record

The organisation analogue of \[explode_person_records()\]: one row per
(certificate, organisation, person, role), so the register table can be
grouped by \`Organisation\` the same way it is grouped by \`Person\`.

## Usage

``` r
explode_organisation_records(register_table)
```

## Arguments

- register_table:

  The register table, with an \`Organisation\` list column (see
  \[add_organisation_records()\]).

## Value

A data frame with the register table's columns plus \`Organisation\`
(the ROR), \`Person\` (the ORCID) and \`Role\`.

# Create the "all organisations" overview table (docs/organisations/index.html)

Mirrors \[create_all_persons_table()\], counting per organisation
instead of per person: the works its people authored, the checks its
people conducted, and how many people it is on the register through.
Only organisations a person's ORCID profile identifies with a ROR appear
at all - see \[add_organisation_records()\] and the provenance note the
pages carry (register#53).

## Usage

``` r
create_all_organisations_table(register_table)
```

## Arguments

- register_table:

  The register table, with an \`Organisation\` list column.

## Value

A list with a single element, the organisations table.

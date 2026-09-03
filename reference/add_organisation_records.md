# Add the organisations behind each certificate's people

The organisation analogue of \[add_person_records()\]: for every
ORCID-identified person on a certificate, the organisations their ORCID
profile identifies with a ROR \*at the time of the work\* - the paper's
publication date for an author, the check date for a codechecker (see
\[person_record_dates()\]). An affiliation held before or after that
window is not recorded, so a page never claims work somebody did
elsewhere (register#53).

## Usage

``` r
add_organisation_records(register_table)
```

## Arguments

- register_table:

  The register table, with a \`Person\` list column (see
  \[add_person_records()\]).

## Value

The register table with an added \`Organisation\` list column, one list
of \`ror, orcid, role, date\` records per certificate (empty for a
certificate whose people have no ROR-identified affiliation).

# Schema.org metadata for an organisation page

An \`Organization\` identified by its ROR, with the checked works its
people authored and the certificates its people produced, mirroring
\[generate_person_schema_org()\] - the organisation is the
\`affiliation\` of the people the register knows, so the works and
reviews it lists are theirs (register#53).

## Usage

``` r
generate_organisation_schema_org(ror, register_table)
```

## Arguments

- ror:

  The organisation's ROR id.

- register_table:

  The organisation's exploded register rows.

## Value

The JSON-LD as a string.

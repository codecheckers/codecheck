# An organisation's metadata, from ROR and Wikidata together

The single entry point the rendering code uses: the ROR record's fields
(see \[ror_metadata_fields()\]) plus the Wikidata logo, if the record
points at an item that has one, and the register venue that shares the
ROR, if any (see \[venue_for_ror()\]).

## Usage

``` r
get_organisation_metadata(ror)
```

## Arguments

- ror:

  A ROR id.

## Value

The list \[ror_metadata_fields()\] returns, with \`logo_url\` and
\`venue\` added.

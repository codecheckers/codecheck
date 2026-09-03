# Extract an organisation's structured metadata fields

Flattens a ROR record into the plain list both the landing page's
metadata panel (\[generate_organisation_metadata_html()\]) and its JSON
representation consume, the way \[get_venue_metadata_fields()\] does for
a venue - the two descriptions of a page must not drift apart.

## Usage

``` r
ror_metadata_fields(record, ror = NULL)
```

## Arguments

- record:

  A ROR record (see \[get_ror_record_cached()\]), or \`NULL\`.

- ror:

  The ROR id, used when the record could not be read.

## Value

A list with \`ror\`, \`ror_url\`, \`name\`, \`aliases\`, \`types\`,
\`city\`, \`country\`, \`established\`, \`website_url\`,
\`wikipedia_url\`, \`wikidata\`, \`status\` (each
\`NA_character\_\`/\`NULL\` when not set) and \`identifiers\`, a list of
\`name\`/\`icon\`/\`value\`/\`link\` lists in the shape
\[parse_venue_identifiers()\] produces.

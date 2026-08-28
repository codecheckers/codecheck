# Extract a venue's structured metadata fields

Pulls a venue's metadata from venues.csv (\`venue_row\`) together with
its type from register.csv (\`venue_type\`) into one plain list. This is
the shared source of truth for both the venue landing page's metadata
panel (\`generate_venue_metadata_html()\`) and its JSON representation
(\`render_register_json()\`, addresses register#183) - both must show
the same information.

## Usage

``` r
get_venue_metadata_fields(venue_row, venue_type = NULL)
```

## Arguments

- venue_row:

  A single-row data frame from CONFIG\$VENUE_DATA (i.e. one row of
  venues.csv).

- venue_type:

  The venue's type (journal/conference/community/ institution, i.e. the
  register.csv \`Type\` column / table_details\$subcat) - not to be
  confused with venues.csv's \`label\` column, which carries GitHub
  issue label values instead.

## Value

A list with \`venue_type\`, \`logo_url\`, \`website_url\`,
\`contact_name\`, \`contact_email\` and \`description\` (each
\`NA_character\_\` when not set), and \`identifiers\` (a list of
\`name\`/\`icon\`/\`value\`/\`link\` lists, possibly empty - see
\[parse_venue_identifiers()\]).

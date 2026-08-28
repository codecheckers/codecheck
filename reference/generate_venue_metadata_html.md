# Generate the venue metadata HTML block for an individual venue landing page

Renders venue type, contact, website, a link to the venue's own
index.json, description and identifiers for a venue via the
\`venue_metadata.html\` whisker template. Fields sourced from venues.csv
are omitted when missing rather than shown empty; the index.json link is
always shown, since that file is always generated alongside this page.

## Usage

``` r
generate_venue_metadata_html(venue_row, venue_type = NULL)
```

## Arguments

- venue_row:

  A single-row data frame from CONFIG\$VENUE_DATA (i.e. one row of
  venues.csv).

- venue_type:

  See \[get_venue_metadata_fields()\]. \`NULL\`/\`NA\` omits the row.

## Value

An HTML string (never \`""\` - the index.json link always renders).

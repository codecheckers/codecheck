# Generate the venue metadata YAML frontmatter block for register.md

Renders the same structured venue metadata as
\[generate_venue_metadata_html()\] and the JSON \`venue\` field (see
\[get_venue_metadata_fields()\]), but as YAML lines for register.md's
frontmatter header rather than as an HTML block in the body -
register.md is served as a plain markdown/API text file, not HTML, so
embedding an HTML \`\<div\>\` in it is wrong (register#84 followup).

## Usage

``` r
generate_venue_metadata_yaml(venue_row, venue_type = NULL)
```

## Arguments

- venue_row:

  A single-row data frame from CONFIG\$VENUE_DATA (i.e. one row of
  venues.csv).

- venue_type:

  See \[get_venue_metadata_fields()\]. \`NULL\`/\`NA\` omits the field.

## Value

A YAML string (ending in a newline), or \`""\` if there is nothing to
add.

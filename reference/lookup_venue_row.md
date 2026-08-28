# Look up a venue's row in venues.csv, with an empty fallback

A venue not (yet) listed in venues.csv still has a type from
register.csv, so callers that only need a type (e.g. the metadata panel,
or its JSON representation) should still get something to work with
rather than skipping the venue entirely.

## Usage

``` r
lookup_venue_row(venue_name)
```

## Arguments

- venue_name:

  The venue's name (register.csv \`Venue\` column / venues.csv \`name\`
  column value).

## Value

A single-row data frame: the matching venues.csv row if found, otherwise
a minimal one-column (\`name\`) data frame.

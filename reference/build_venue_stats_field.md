# Build a venue's structured stats.json/index.json "venue" field

Shared by \[render_register_json()\] (a full render, which already knows
the venue's name/type from \`table_details\`) and
\[register_update_stats()\] (which recovers them by parsing the venue's
own directory path, since it works from an already-rendered
\`register.json\` with no \`table_details\` to hand it) - both then need
the exact same fields, sourced from \[get_venue_metadata_fields()\], the
same panel-and-JSON single source of truth the venue landing page's
metadata panel uses.

## Usage

``` r
build_venue_stats_field(venue_name, venue_type)
```

## Arguments

- venue_name:

  The venue's name (register.csv \`Venue\` column).

- venue_type:

  The venue's type (register.csv \`Type\` column).

## Value

A list suitable for \`stats_data\$venue\`/\`sub_stats\$venue\`.

# Build a codechecker's structured stats.json "codechecker" field

Shared by \[render_register_json()\] and \[register_update_stats()\] -
see \[build_venue_stats_field()\] for why the same field needs building
twice. Addresses register#78.

## Usage

``` r
build_codechecker_stats_field(identifier, register_table)
```

## Arguments

- identifier:

  The codechecker's ORCID or GitHub handle.

- register_table:

  The codechecker's register rows, needs \`Venue\`/\`Type\`.

## Value

A list suitable for
\`stats_data\$codechecker\`/\`sub_stats\$codechecker\`.

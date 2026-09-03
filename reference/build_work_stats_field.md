# Build a work's structured index.json "work" field

Shared by \[render_register_json()\] and \[register_update_stats()\] -
see \[build_venue_stats_field()\] for why the same field needs building
twice. Addresses codecheckers/register#150's machine-readable
representation.

## Usage

``` r
build_work_stats_field(doi, register_table)
```

## Arguments

- doi:

  The work's DOI.

- register_table:

  The work's register rows, see \[get_work_metadata_fields()\].

## Value

A list suitable for \`stats_data\$work\`/\`sub_stats\$work\`.

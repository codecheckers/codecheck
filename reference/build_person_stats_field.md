# Build a person's structured stats.json "person" field

Shared by \[render_register_json()\] and \[register_update_stats()\] -
see \[build_venue_stats_field()\] for why the same field needs building
twice. The \#123 analogue of \[build_codechecker_stats_field()\],
extended with the works-authored count a codechecker-only page never
had.

## Usage

``` r
build_person_stats_field(orcid, register_table)
```

## Arguments

- orcid:

  The person's ORCID.

- register_table:

  The person's exploded, per-role register rows (see
  \[explode_person_records()\]), needs a \`Role\` column.

## Value

A list suitable for \`stats_data\$person\`/\`sub_stats\$person\`.

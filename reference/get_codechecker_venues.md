# Compute a codechecker's contributed venues, with per-venue check counts

Shared source of truth for the "Contributed checks" row in the
codechecker metadata panel (register#74/#189/#83) and the \`venues\`
field in a codechecker's \`stats.json\` (register#78).

## Usage

``` r
get_codechecker_venues(register_table)
```

## Arguments

- register_table:

  The already-filtered per-codechecker register table (raw, i.e. before
  \`add_venue_hyperlinks_reg()\` has rewritten \`Venue\` into a markdown
  link - or a \`register.json\` re-read as a data frame, which keeps
  \`Venue\`/\`Type\` as plain strings either way).

## Value

A data frame with columns \`Venue\`, \`Type\`, \`cert_count\` - one row
per distinct venue, sorted by \`Venue\`. Zero rows (same columns) if the
input has no usable \`Venue\`/\`Type\` data.

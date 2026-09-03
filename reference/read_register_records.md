# The register, in the shape the model consumes

Read from a rendered register directory rather than from
\`register.csv\`: the model needs the enriched fields (paper title and
DOI, the codecheckers with their ORCIDs, the certificate PDF), and those
are exactly what a render has already resolved and written to \`docs/\`.
Reading them back is offline, takes seconds, and cannot disagree with
the register website.

## Usage

``` r
read_register_records(dir)
```

## Arguments

- dir:

  the register repository, containing \`docs/\` and \`venues.csv\`

## Value

a list with \`certificates\` (one row each, \`Codechecker\` a list
column) and \`venues\`

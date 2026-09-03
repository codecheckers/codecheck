# The register venue that carries a ROR, if any

An institution venue can name its ROR in \`venues.csv\`'s
\`identifiers\` column, which is the same organisation this page is
about - commissioning a check and employing the people who did it are
different facts, so the two pages stay separate and link to each other
instead.

## Usage

``` r
venue_for_ror(ror)
```

## Arguments

- ror:

  A ROR id.

## Value

A list with \`name\`, \`longname\` and \`url\` (the venue's page), or
\`NULL\` when no venue carries this ROR.

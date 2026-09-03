# Turn an ORCID partial date into a \`Date\`

ORCID dates carry a year and, often, no month or day at all. \`bound\`
decides what an absent month/day means: the start of the year for a
lower bound, its end for an upper one, so a year-only affiliation covers
the whole year instead of just its first day.

## Usage

``` r
orcid_date(date, bound = c("lower", "upper"))
```

## Arguments

- date:

  An ORCID date list (\`year\`/\`month\`/\`day\`), or NULL

- bound:

  Either "lower" or "upper"

## Value

A \`Date\`, or \`NA\` when there is no year

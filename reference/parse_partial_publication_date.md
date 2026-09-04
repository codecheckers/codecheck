# Parse a partial or full publication date string into an ISO date

Publication-date metadata found in the wild is often partial: a bare
year ("2022"), a year and month ("2022/6", separators "/" or "-"), a
full date ("2025/07/04", "2025-07-04"), or a full ISO 8601 timestamp
("2025-12-11T15:19:52+0100", schema.org's \`datePublished\`). The
statistics dashboard's interval calculations need one concrete calendar
day per work, so a partial date is filled in at its most likely midpoint
(day 15 of a known month, July 2 of a bare year) rather than defaulted
to the 1st - which would systematically bias every partial date toward
"early in the period" - or left as NA, which would silently drop the
work from the interval statistics entirely.

## Usage

``` r
parse_partial_publication_date(date_str)
```

## Arguments

- date_str:

  A date string in one of the formats above, or NA/NULL

## Value

An ISO "YYYY-MM-DD" string, or NA_character\_ if unparseable

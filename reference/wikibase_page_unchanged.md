# Whether a generated page would say anything new

Every generated page ends in a "Generated ..." timestamp, so a rewrite
always differs from what is there. Comparing without it keeps a rerun
from adding a revision that changes nothing but the time.

## Usage

``` r
wikibase_page_unchanged(current, text)
```

## Arguments

- current:

  the page as it is, \`NA\` if it does not exist

- text:

  the page as it would be written

## Value

\`TRUE\` if writing \`text\` would change nothing but the timestamp

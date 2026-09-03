# The bare ROR id

ORCID and \`venues.csv\` both store a ROR as the full
\`https://ror.org/\<id\>\` URL, while the API and the page slugs use the
id on its own.

## Usage

``` r
normalize_ror(ror)
```

## Arguments

- ror:

  A ROR id or ROR URL

## Value

The id without the \`https://ror.org/\` prefix

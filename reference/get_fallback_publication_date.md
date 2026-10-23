# A work's publication date when OpenAlex has none of its own

The registry first, then the landing page, see
\[get_registry_publication_date_result()\].

## Usage

``` r
get_fallback_publication_date(reference)
```

## Arguments

- reference:

  The paper reference

## Value

A list with \`status\`, \`value\` and \`source\` ("registry" or "page")

# A read-only Action API request

A read-only Action API request

## Usage

``` r
wikibase_get(handle, params, api = WIKIBASE_INSTANCE$api)
```

## Arguments

- handle:

  an \`httr\` handle, or \`NULL\` for an anonymous request

- params:

  the query parameters, \`format = "json"\` is added

- api:

  the Action API to read from, the CODECHECK Wikibase by default

## Value

the parsed response

# Look up an organisation's record on ror.org

There is no maintained R package wrapping the ROR API (\`rorcid\` is
ORCID), so the v2 REST API is called directly, through the same request
and caching machinery as the register's other external metadata.

## Usage

``` r
get_ror_record_result(ror)
```

## Arguments

- ror:

  A ROR id, with or without the \`https://ror.org/\` prefix.

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`,
the parsed ROR record or \`NULL\`.

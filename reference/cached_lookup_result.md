# Same as [`cached_lookup`](http://codecheck.org.uk/codecheck/reference/cached_lookup.md), but returns the full result

Callers that need to tell a confirmed "absent" apart from an
inconclusive "failed" lookup (see
[`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md))
need the status, not just the value
[`cached_lookup`](http://codecheck.org.uk/codecheck/reference/cached_lookup.md)
returns.

## Usage

``` r
cached_lookup_result(key, dirs, lookup, counts = TRUE)
```

## Arguments

- key:

  List of values identifying the lookup

- dirs:

  Cache subdirectory below the R.cache root

- lookup:

  Function of no arguments returning a list with elements \`status\`
  ("found", "absent" or "failed") and \`value\`

- counts:

  Whether a lookup that fails because a service is down counts as
  missing data, see \[collect_outages()\]; not for a field whose
  previous value \[resolve_external_field()\] keeps

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`

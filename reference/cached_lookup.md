# Cache the result of a metadata lookup on disk, but only when conclusive

The register is rendered from thousands of requests to external APIs,
and rendering the same certificate repeatedly re-runs the same lookups.
Caching them keeps renders fast and stable, but caching a failed request
would persist a gap in the register until the cache is cleared, which is
how certificates lost their OpenAlex ID (register#185).

## Usage

``` r
cached_lookup(key, dirs, lookup)
```

## Arguments

- key:

  List of values identifying the lookup

- dirs:

  Cache subdirectory below the R.cache root

- lookup:

  Function of no arguments returning a list with elements \`status\`
  ("found", "absent" or "failed") and \`value\`

## Value

The \`value\` element of the lookup result

## Details

Only conclusive results are stored: a value that was found, or an
absence the API actually confirmed. Failed requests (network errors,
rate limiting) are returned but not stored, so the next render retries
them.

The cache lives under the R.cache root and is therefore removed by
[`register_clear_cache`](http://codecheck.org.uk/codecheck/reference/register_clear_cache.md),
i.e. by \`make clean\`.

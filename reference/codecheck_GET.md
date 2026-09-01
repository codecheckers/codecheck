# Custom HTTP GET with proper User-Agent header and a bounded timeout

Wraps [`httr::GET()`](https://httr.r-lib.org/reference/GET.html) with a
descriptive User-Agent to avoid being blocked by services like Figshare
that reject default libcurl requests, especially from CI runner IPs
(e.g., GitHub Actions).

## Usage

``` r
codecheck_GET(url, ..., timeout_seconds = 30)
```

## Arguments

- url:

  The URL to request

- ...:

  Additional arguments passed to
  [`httr::GET()`](https://httr.r-lib.org/reference/GET.html) - a
  caller's own
  [`httr::timeout()`](https://httr.r-lib.org/reference/timeout.html)
  here overrides the default.

- timeout_seconds:

  Maximum time for the whole request/response cycle.

## Value

An `httr` response object

## Details

Also bounds the request to `timeout_seconds`: plain
[`httr::GET()`](https://httr.r-lib.org/reference/GET.html) has no
timeout at all, so a server that accepts the connection but never
answers (rather than erroring or rate-limiting, which
[`codecheck_GET_retry()`](http://codecheck.org.uk/codecheck/reference/codecheck_GET_retry.md)
already handles) hangs the request - and with it, the whole
single-threaded render - indefinitely. A render touches many
certificates across several external APIs in one run, so any one of them
having a bad moment stalls everything after it with no log output to say
why. Bounding it here means the caller gets an error back to handle
(\`codecheck_GET_retry()\` retries it; a bare \`codecheck_GET()\` caller
sees a \`try\`/\`tryCatch\`-able failure) instead of a silent,
unrecoverable hang.

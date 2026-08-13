# Custom HTTP GET with proper User-Agent header

Wraps [`httr::GET()`](https://httr.r-lib.org/reference/GET.html) with a
descriptive User-Agent to avoid being blocked by services like Figshare
that reject default libcurl requests, especially from CI runner IPs
(e.g., GitHub Actions).

## Usage

``` r
codecheck_GET(url, ...)
```

## Arguments

- url:

  The URL to request

- ...:

  Additional arguments passed to
  [`httr::GET()`](https://httr.r-lib.org/reference/GET.html)

## Value

An `httr` response object

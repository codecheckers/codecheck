# GET an OpenAlex API URL with the configured API key and retries

GET an OpenAlex API URL with the configured API key and retries

## Usage

``` r
codecheck_GET_openalex(url, ...)
```

## Arguments

- url:

  The OpenAlex API URL

- ...:

  Additional arguments passed to
  [`codecheck_GET_retry()`](http://codecheck.org.uk/codecheck/reference/codecheck_GET_retry.md)

## Value

An `httr` response object, or NULL if every attempt errored

# Fetch and cache codecheckers.csv data from GitHub

This function downloads the codecheckers registry from the
codecheckers/codecheckers repository and caches it for performance.

## Usage

``` r
get_codecheckers_data(..., envir = parent.frame())
```

## Arguments

- ...:

  Additional arguments passed to the memoization mechanism

- envir:

  Environment for memoization caching (default: parent.frame())

## Value

A data frame with columns: name, handle, ORCID, contact, fields,
languages

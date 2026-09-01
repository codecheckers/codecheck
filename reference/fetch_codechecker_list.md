# Fetch one codechecker list from GitHub

A failed fetch is a warning and an empty data frame, never an error: a
render without network access should still produce pages, just without
the profile panel. The same holds for a list that does not (yet) carry
every column - see \[normalize_codechecker_list()\].

## Usage

``` r
fetch_codechecker_list(..., envir = parent.frame())
```

## Arguments

- url:

  Raw URL of the CSV.

## Value

A data frame with the columns of \[CODECHECKER_LIST_COLUMNS\].

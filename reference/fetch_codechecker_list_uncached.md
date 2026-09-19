# Fetch one codechecker list from GitHub

A failed fetch is a warning and \`NULL\`, never an error, see
\[fetch_codechecker_list()\] for what a render does then.

## Usage

``` r
fetch_codechecker_list_uncached(url)
```

## Arguments

- url:

  Raw URL of the CSV.

## Value

The list as read, or \`NULL\` when it could not be fetched.

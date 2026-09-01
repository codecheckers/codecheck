# Get codechecker profile information by GitHub handle

Searches all three codechecker lists, see \[all_codechecker_records()\].

## Usage

``` r
get_codechecker_profile_by_handle(handle)
```

## Arguments

- handle:

  The GitHub handle (without @ prefix)

## Value

A list with profile information (name, github_handle, orcid, fields,
languages, source) or NULL if not found

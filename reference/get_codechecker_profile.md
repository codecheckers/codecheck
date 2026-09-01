# Get codechecker profile information by ORCID

Searches all three codechecker lists, see \[all_codechecker_records()\].

## Usage

``` r
get_codechecker_profile(orcid)
```

## Arguments

- orcid:

  The ORCID identifier (without URL prefix)

## Value

A list with profile information (name, github_handle, orcid, fields,
languages, source) or NULL if not found

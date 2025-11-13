# Get codechecker profile information by ORCID

Retrieves profile information for a codechecker from the codecheckers
registry.

## Usage

``` r
get_codechecker_profile(orcid)
```

## Arguments

- orcid:

  The ORCID identifier (without URL prefix)

## Value

A list with profile information (name, handle, orcid, fields, languages)
or NULL if not found

# Get codechecker profile information by GitHub handle

Retrieves profile information for a codechecker from the codecheckers
registry.

## Usage

``` r
get_codechecker_profile_by_handle(handle)
```

## Arguments

- handle:

  The GitHub handle (without @ prefix)

## Value

A list with profile information (name, handle, orcid, fields, languages)
or NULL if not found

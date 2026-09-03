# Cached version of \[get_orcid_affiliations_result()\]

Caches on disk, but only when ORCID actually answered, see
\[cached_lookup()\]. Cleared by \[register_clear_cache()\].

## Usage

``` r
get_orcid_affiliations_cached(orcid)
```

## Arguments

- orcid:

  An ORCID identifier (NNNN-NNNN-NNNN-NNNX).

## Value

The affiliation data frame

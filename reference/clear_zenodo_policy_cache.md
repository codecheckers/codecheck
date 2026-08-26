# Drop the cached policy metadata of one Zenodo record

Drop the cached policy-check metadata of a Zenodo record

## Usage

``` r
clear_zenodo_policy_cache(record_id)
```

## Arguments

- record_id:

  Zenodo record ID

## Value

TRUE if a cache entry was removed, FALSE otherwise, invisibly

## Details

\[check_register_zenodo_policy()\] caches record metadata, so a record
that was just curated would keep being reported with its pre-curation
findings until the whole cache is cleared. Invalidating the single
record keeps the rest of the cache warm.

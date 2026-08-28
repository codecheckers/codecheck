# Drop the cached policy metadata of one ResearchEquals module

Drop the cached policy metadata of one ResearchEquals module

## Usage

``` r
clear_researchequals_policy_cache(version_id)
```

## Arguments

- version_id:

  ResearchEquals version ID

## Value

TRUE if a cache entry was removed, FALSE otherwise, invisibly

## Details

\[check_register_researchequals_policy()\] caches version metadata, so a
module that was just corrected would keep being reported with its
earlier findings until the whole cache is cleared. Invalidating the
single version keeps the rest of the cache warm.

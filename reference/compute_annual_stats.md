# Compute annual statistics from the register table

Computes per-year breakdowns of checks, venues, codecheckers, and report
platforms. Used to enrich stats.json (addresses register#144).

## Usage

``` r
compute_annual_stats(register_table)
```

## Arguments

- register_table:

  The full preprocessed register table (before column filtering)

## Value

A list of annual statistics

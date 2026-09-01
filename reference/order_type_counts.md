# Order a codechecker's per-type check counts for display

Largest type first, ties broken alphabetically, so the stacked bar
(register#92) and the donut (register#207) always segment a given
codechecker in the same order.

## Usage

``` r
order_type_counts(counts)
```

## Arguments

- counts:

  A named integer vector of checks per venue type.

## Value

The same vector, reordered.

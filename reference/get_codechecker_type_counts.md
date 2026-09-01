# Aggregate a codechecker's checks from venues to venue types

The per-type counts behind the stacked bar (register#92) and the donut
(register#207). Built on \[get_codechecker_venues()\] so it counts
exactly what the "Contributed checks" row lists, only grouped one level
up.

## Usage

``` r
get_codechecker_type_counts(register_table)
```

## Arguments

- register_table:

  See \[get_codechecker_venues()\].

## Value

A named integer vector of checks per venue type, largest first; length
zero if there is nothing to count.

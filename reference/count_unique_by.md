# Count unique values per group, as a list sorted by group name

\`tapply()\` on zero rows (or on groups that are all NA) returns an
array without names, which \`order(names(...))\` cannot sort; this
returns an empty list instead.

## Usage

``` r
count_unique_by(values, groups)
```

## Arguments

- values:

  Values to count

- groups:

  Group of each value; NA groups are dropped

## Value

A named list of integer counts, possibly empty

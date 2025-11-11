# Create All Venues Table

This function generates a table with all unique venues and their
corresponding types. It also adds columns for the number of codechecks
and a slug for the venue name.

## Usage

``` r
create_all_venues_table(register_table)
```

## Arguments

- register_table:

  The data frame containing the original register data.

## Value

A data frame with venues, their types, the number of codechecks, and a
slug name.

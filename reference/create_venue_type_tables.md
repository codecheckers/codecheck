# Create Venue Type-Specific Tables

Generates tables for each venue type by filtering the register data. It
adds columns for the venue slug and the number of codechecks for each
venue type.

## Usage

``` r
create_venue_type_tables(register_table)
```

## Arguments

- register_table:

  The data frame containing the original register data.

## Value

A list of tables, one for each venue type.

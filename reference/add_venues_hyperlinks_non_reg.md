# Add Hyperlinks to Venues Table

Adds hyperlinks to the venue names, venue types, and the number of
codechecks in the venues table. If a subcategory is provided, it
generates links based on venue types.

## Usage

``` r
add_venues_hyperlinks_non_reg(table, subcat)
```

## Arguments

- table:

  The data frame containing the venues data.

- subcat:

  An optional string specifying the subcategory (venue type) for the
  venues.

## Value

The data frame with hyperlinks added to the appropriate columns.

# Add Hyperlinks to All Venues Table

Adds hyperlinks to the venue names, venue types, and the number of
codechecks in the all venues table. The links point to the venue's page
and the venue type's page. Uses relative paths for HTML display
(absolute URLs used in JSON/CSV).

## Usage

``` r
add_all_venues_hyperlinks_non_reg(table, table_details = NULL)
```

## Arguments

- table:

  The data frame containing data on all venues.

- table_details:

  A list containing metadata including output_dir for relative path
  calculation.

## Value

The data frame with hyperlinks added to the appropriate columns.

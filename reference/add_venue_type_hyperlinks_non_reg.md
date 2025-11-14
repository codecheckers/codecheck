# Add Hyperlinks to Venue Type-Specific Table

Adds hyperlinks to the venue names and the number of codechecks in the
venue type-specific table. The links point to the venue's page for each
venue type. Uses relative paths for HTML display (absolute URLs used in
JSON/CSV).

## Usage

``` r
add_venue_type_hyperlinks_non_reg(table, venue_type, table_details = NULL)
```

## Arguments

- table:

  The data frame containing the venue type-specific data.

- venue_type:

  A string specifying the venue type.

- table_details:

  A list containing metadata including output_dir for relative path
  calculation.

## Value

The data frame with hyperlinks added to the appropriate columns.

# Generate Table Details for Non-Register Files

Generates metadata for non-register tables, including subcategory,
title, subtext, extra text, and output directory. It is used to prepare
the table for rendering.

## Usage

``` r
generate_table_details_non_reg(table, filter, subcat = NULL)
```

## Arguments

- table:

  The data frame containing the filtered table.

- filter:

  A string specifying the filter applied to the table.

- subcat:

  An optional string for the subcategory (if applicable).

## Value

A list containing metadata such as title, subtext, and output directory
for the table.

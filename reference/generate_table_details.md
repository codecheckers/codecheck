# Generate Table Details

This function generates metadata and details for a specific table,
including the table name, slugified name, subcategory (if applicable),
and the output directory. It is used when rendering tables in different
formats.

## Usage

``` r
generate_table_details(table_key, table, filter, is_reg_table = TRUE)
```

## Arguments

- table_key:

  The key (name) of the table being processed.

- table:

  The data frame containing the table data.

- filter:

  A string specifying the filter applied to the table data.

- is_reg_table:

  A boolean indicating whether the table is a register table (default is
  TRUE).

## Value

A list of table details including name, slugified name, subcategory (if
applicable), and output directory.

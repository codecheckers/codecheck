# Creates a markdown table from a register template Adds title to the markdown and adjusts the column widths of the table before returning it.

Creates a markdown table from a register template Adds title to the
markdown and adjusts the column widths of the table before returning it.

## Usage

``` r
create_md_table(register_table, table_details, filter)
```

## Arguments

- register_table:

  DataFrame of the register data.

- table_details:

  List containing details such as the table name, subcat name.

- filter:

  Type of filter (e.g., "venues", "codecheckers").

## Value

The markdown table

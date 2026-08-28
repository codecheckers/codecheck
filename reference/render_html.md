# Renders html for a single table

This function can be used to render both register and non-register
tables

## Usage

``` r
render_html(table, table_details, filter, full_register_table = NULL)
```

## Arguments

- table:

  The table to render to HTML

- table_details:

  List containing details such as the table name, subcat name.

- filter:

  The filter

- full_register_table:

  Optional table for this filter group with all register columns
  retained (i.e. before \[filter_and_drop_register_columns()\] ran on
  \`table\`). Used for Schema.org generation on codechecker pages, which
  needs the Repository column that the HTML column set does not include.

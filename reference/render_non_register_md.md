# Render Non-Register Markdown Table

Renders the table in Markdown format, including adding hyperlinks to the
relevant columns. It adjusts column widths and saves the output as a
Markdown file.

## Usage

``` r
render_non_register_md(table, table_details, filter)
```

## Arguments

- table:

  The data frame containing the filtered table.

- table_details:

  A list of metadata about the table (e.g., title, subtext, extra text).

- filter:

  A string specifying the filter applied (e.g., "venues",
  "codecheckers").

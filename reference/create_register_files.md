# Create Register Files

This function processes the register table based on different filter
types and output formats. It groups the register data by the specified
filters, generates nested tables, and then creates markdown, HTML, and
JSON files for each individual table.

## Usage

``` r
create_register_files(register_table, filter_by, outputs)
```

## Arguments

- register_table:

  The original register table

- filter_by:

  A list specifying the filters to be applied (e.g., "venues",
  "codecheckers").

- outputs:

  A list specifying the output formats to generate (e.g., "md", "html",
  "json").

## Value

None. The function generates files in the specified formats.

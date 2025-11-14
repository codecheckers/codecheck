# Render Register in Specified Output Format

This function renders the register table into different output formats
based on the specified type. It supports rendering the table as
Markdown, HTML, or JSON. All outputs are sorted by certificate
identifier for consistency.

## Usage

``` r
render_register(register_table, table_details, filter = NA, output_type)
```

## Arguments

- register_table:

  The register table that needs to be rendered into different files.

- table_details:

  A list of details related to the table (e.g., output directory,
  metadata).

- filter:

  A string specifying the filter applied to the register data.

- output_type:

  A string specifying the desired output format "json" for JSON, "csv"
  for CSVs, "md" for MD and "html" for HTMLs.

## Value

None. The function generates a file in the specified format.

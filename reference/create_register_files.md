# Create Register Files

This function processes the register table based on different filter
types and output formats. It groups the register data by the specified
filters, generates nested tables, and then creates markdown, HTML, and
JSON files for each individual table.

## Usage

``` r
create_register_files(
  register_table,
  filter_by,
  outputs,
  parallel = FALSE,
  ncores = NULL
)
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

- parallel:

  Whether to render the pages of a filter in parallel. Each page writes
  into its own output directory, so the items of one filter are
  independent of each other.

- ncores:

  Number of workers to use when \`parallel\` is TRUE, defaults to one
  less than the machine has.

## Value

None. The function generates files in the specified formats.

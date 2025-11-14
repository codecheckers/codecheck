# Function for adding clickable links to the codecheck venue pages for each entry in the register table. Uses relative paths for HTML display (absolute URLs used in JSON/CSV).

Function for adding clickable links to the codecheck venue pages for
each entry in the register table. Uses relative paths for HTML display
(absolute URLs used in JSON/CSV).

## Usage

``` r
add_venue_hyperlinks_reg(register_table, table_details = NULL)
```

## Arguments

- register_table:

  The register table

- table_details:

  List containing output directory for relative path calculation

## Value

The adjusted register table

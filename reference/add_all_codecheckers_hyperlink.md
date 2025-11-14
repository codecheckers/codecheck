# Add Hyperlinks to Codecheckers Table

Adds hyperlinks to the codecheckers table by modifying the codechecker
names, number of codechecks, and ORCID IDs into clickable links. Uses
relative paths for internal links (codecheckers pages) and absolute URLs
for external links.

## Usage

``` r
add_all_codecheckers_hyperlink(table, table_details = NULL)
```

## Arguments

- table:

  The codecheckers table

- table_details:

  A list containing metadata including output_dir for relative path
  calculation.

## Value

The data frame with added hyperlinks in the specified columns.

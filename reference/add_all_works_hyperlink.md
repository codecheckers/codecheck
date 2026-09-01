# Add hyperlinks to the "all works" overview table

Mirrors \[add_all_codecheckers_hyperlink()\]. The DOI, which may itself
contain "/" characters, is what the relative link is built from -
\`./10.1093/gigascience/giaa026/\` correctly resolves from
\`docs/works/index.html\` to
\`docs/works/10.1093/gigascience/giaa026/\`, the same nesting
\[generate_output_dir()\] already produces.

## Usage

``` r
add_all_works_hyperlink(table, table_details = NULL)
```

## Arguments

- table:

  The works table (see \[create_all_works_table()\]).

- table_details:

  Unused; kept for signature parity with the other
  \`add_all\_\*\_hyperlink()\` functions.

## Value

The data frame with hyperlinks added.

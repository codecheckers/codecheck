# Turn the Person column into links to the person pages

The organisation page's tables show who each row is attributed through,
by name rather than by ORCID. Links are relative, like every other
internal link (see \[add_venue_hyperlinks_reg()\]), so a locally served
\`docs/\` works.

## Usage

``` r
add_person_hyperlinks_reg(register_table, table_details = NULL)
```

## Arguments

- register_table:

  A register table with a \`Person\` (ORCID) column.

- table_details:

  List containing the page's \`output_dir\`.

## Value

The table, with \`Person\` rewritten as a markdown link.

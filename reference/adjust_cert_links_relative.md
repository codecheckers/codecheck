# Turn the plain Certificate column into a relative markdown link

\`add_cert_links()\` leaves \`register_table\$Certificate\` as the plain
identifier; this is the one place that turns it into the markdown link
\`\[id\](path)\` that the md/HTML table rendering needs, using a
relative path whose depth depends on the output directory. JSON and CSV
exports don't call this function and keep the plain \`Certificate
ID\`/absolute \`Certificate Link\` columns from \`add_cert_links()\`
instead.

## Usage

``` r
adjust_cert_links_relative(register_table, table_details)
```

## Arguments

- register_table:

  The register table with a plain Certificate column

- table_details:

  List containing output directory and other metadata

## Value

The adjusted register table with a markdown-linked Certificate column

## Examples

``` r
if (FALSE) { # \dontrun{
# For root level (docs/index.html):        2020-001 -> [2020-001](./certs/2020-001/)
# For nested level (docs/venues/.../...): 2020-001 -> [2020-001](../../../certs/2020-001/)
} # }
```

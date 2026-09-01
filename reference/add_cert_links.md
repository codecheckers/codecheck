# Function for adding certificate identifier and link as extra columns

The \`Certificate\` column itself is left as the plain identifier -
callers that need it as a markdown link (only the md/HTML table
rendering does, via \[adjust_cert_links_relative()\]) build that
themselves at render time. Every other consumer (JSON/CSV output,
Schema.org generation, Zenodo/ ResearchEquals policy checks, ...) can
then read \`Certificate\` directly without having to strip markdown
syntax back out of it first.

## Usage

``` r
add_cert_links(register_table)
```

## Arguments

- register_table:

  The register table to be adjusted.

## Value

The adjusted register table with new columns for certificate identifier
and certificate URL

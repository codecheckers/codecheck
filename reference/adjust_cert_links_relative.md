# Convert certificate links from absolute to relative paths based on page depth

Transforms absolute certificate URLs to relative paths for HTML/Markdown
display. The depth of the relative path is calculated based on the
output directory structure. JSON and CSV exports retain absolute URLs as
they don't call this function.

## Usage

``` r
adjust_cert_links_relative(register_table, table_details)
```

## Arguments

- register_table:

  The register table with Certificate column containing absolute URLs

- table_details:

  List containing output directory and other metadata

## Value

The adjusted register table with relative certificate links

## Examples

``` r
if (FALSE) { # \dontrun{
# For root level (docs/index.html):
#   https://codecheck.org.uk/register/certs/2020-001/ -> ./certs/2020-001/
# For nested level (docs/venues/journals/gigascience/index.html):
#   https://codecheck.org.uk/register/certs/2020-001/ -> ../../../certs/2020-001/
} # }
```

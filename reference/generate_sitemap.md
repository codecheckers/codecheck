# Generate sitemap.xml for the register

Creates a sitemap.xml file listing all generated pages in the register
for search engine optimization and crawling.

## Usage

``` r
generate_sitemap(
  register_table,
  filter_by = c("venues", "codecheckers"),
  output_dir = "docs",
  base_url = CONFIG$HYPERLINKS[["register"]],
  lastmod = format(Sys.Date(), "%Y-%m-%d")
)
```

## Arguments

- register_table:

  The preprocessed register table with all entries

- filter_by:

  List of filters used (e.g., "venues", "codecheckers")

- output_dir:

  Output directory for the sitemap (default: "docs")

- base_url:

  Base URL for the register (default: from CONFIG)

- lastmod:

  Last modification date (default: current date in ISO 8601 format)

## Value

Invisibly returns the path to the generated sitemap.xml

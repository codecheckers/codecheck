# Generate robots.txt for the register

Creates a robots.txt file that allows all search engines to crawl the
register and references the sitemap.xml file.

## Usage

``` r
generate_robots_txt(
  output_dir = "docs",
  base_url = CONFIG$HYPERLINKS[["register"]]
)
```

## Arguments

- output_dir:

  Output directory for robots.txt (default: "docs")

- base_url:

  Base URL for the register (default: from CONFIG)

## Value

Invisibly returns the path to the generated robots.txt

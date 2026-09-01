# Generate the register's 404 page

\`docs/\` is served as its own GitHub Pages project site (verified live:
\`codecheck.org.uk/register/\<anything\>\` returns GitHub's stock 404
today, not the parent \`codecheck.org.uk\` site's Jekyll one), so a
\`docs/404.html\` here is what every missing path under \`/register/\`
gets shown.

## Usage

``` r
generate_404_page(output_dir = "docs")
```

## Arguments

- output_dir:

  Output directory (default: "docs")

## Value

Invisibly returns the path to the generated 404.html

## Details

Reuses \[generate_navigation_header()\] for the nav bar - the same
markup every other page's prefix uses - rather than duplicating it;
there is no pandoc render step here, this is a small hand-built page
like a codechecker/person redirect stub.

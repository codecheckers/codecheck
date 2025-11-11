# Render HTML file for certificate output

Internal helper function to render HTML files (converts to PDF via
wkhtmltopdf).

## Usage

``` r
render_manifest_html(path, comment)
```

## Arguments

- path:

  \- Path to the HTML file

- comment:

  \- Comment describing the file

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

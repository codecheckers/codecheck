# Render HTML file for certificate output

Internal helper function to render HTML files (converts to PDF via
wkhtmltopdf).

## Usage

``` r
render_manifest_html(path, comment, name = basename(path))
```

## Arguments

- path:

  \- Path to the HTML file

- comment:

  \- Comment describing the file

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

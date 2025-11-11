# Render SVG image for certificate output

Internal helper function to render SVG files (converts to PDF first).

## Usage

``` r
render_manifest_svg(path, comment)
```

## Arguments

- path:

  \- Path to the SVG file

- comment:

  \- Comment/caption for the image

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

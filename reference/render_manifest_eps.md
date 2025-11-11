# Render EPS image for certificate output

Internal helper function to render EPS files (LaTeX handles conversion).

## Usage

``` r
render_manifest_eps(path, comment)
```

## Arguments

- path:

  \- Path to the EPS file

- comment:

  \- Comment/caption for the image

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

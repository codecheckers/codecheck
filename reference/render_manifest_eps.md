# Render EPS image for certificate output

Internal helper function to render EPS files (LaTeX handles conversion).

## Usage

``` r
render_manifest_eps(path, comment, name = basename(path))
```

## Arguments

- path:

  \- Path to the EPS file

- comment:

  \- Comment/caption for the image

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

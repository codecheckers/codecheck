# Render SVG image for certificate output

Internal helper function to render SVG files (converts to PDF first).

## Usage

``` r
render_manifest_svg(path, comment, name = basename(path), base_dir = NULL)
```

## Arguments

- path:

  \- Path to the SVG file

- comment:

  \- Comment/caption for the image

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

- base_dir:

  \- Directory the image is linked relative to, or `NULL` to link it by
  `path`; files are read by `path` either way

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

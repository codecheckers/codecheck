# Render text file for certificate output

Internal helper function to render TXT and Rout files.

## Usage

``` r
render_manifest_text(path, comment, name = basename(path))
```

## Arguments

- path:

  \- Path to the text file

- comment:

  \- Comment describing the file

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

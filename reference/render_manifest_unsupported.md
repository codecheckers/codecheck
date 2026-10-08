# Render unsupported file type for certificate output

Internal helper function to handle unsupported file types.

## Usage

``` r
render_manifest_unsupported(path, comment, name = basename(path))
```

## Arguments

- path:

  \- Path to the file

- comment:

  \- Comment describing the file

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

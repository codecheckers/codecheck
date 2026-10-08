# Render JSON file for certificate output

Internal helper function to render JSON files with pretty-printing.

## Usage

``` r
render_manifest_json(path, comment, max_lines = 50, name = basename(path))
```

## Arguments

- path:

  \- Path to the JSON file

- comment:

  \- Comment describing the file

- max_lines:

  \- Maximum number of lines to display (default: 50)

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

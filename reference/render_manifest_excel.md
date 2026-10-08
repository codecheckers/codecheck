# Render Excel file for certificate output

Internal helper function to render XLS/XLSX files.

## Usage

``` r
render_manifest_excel(path, comment, name = basename(path))
```

## Arguments

- path:

  \- Path to the Excel file

- comment:

  \- Comment describing the file

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

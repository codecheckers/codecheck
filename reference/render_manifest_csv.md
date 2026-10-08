# Render CSV file for certificate output

Internal helper function to render CSV files with skimr statistics.

## Usage

``` r
render_manifest_csv(path, comment, name = basename(path))
```

## Arguments

- path:

  \- Path to the CSV file

- comment:

  \- Comment describing the file

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

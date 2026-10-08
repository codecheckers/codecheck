# Render TSV file for certificate output

Internal helper function to render TSV files with skimr statistics.

## Usage

``` r
render_manifest_tsv(path, comment, name = basename(path))
```

## Arguments

- path:

  \- Path to the TSV file

- comment:

  \- Comment describing the file

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

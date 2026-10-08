# Render PDF file for certificate output

Internal helper function to render PDF files (handles multi-page PDFs).

## Usage

``` r
render_manifest_pdf(path, comment, name = basename(path))
```

## Arguments

- path:

  \- Path to the PDF file

- comment:

  \- Comment/caption for the PDF

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

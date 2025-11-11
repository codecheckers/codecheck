# Render PDF file for certificate output

Internal helper function to render PDF files (handles multi-page PDFs).

## Usage

``` r
render_manifest_pdf(path, comment)
```

## Arguments

- path:

  \- Path to the PDF file

- comment:

  \- Comment/caption for the PDF

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

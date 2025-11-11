# Generates HTML files for each certificate listed in the given register table. It checks for the existence of the certificate PDF, downloads it if necessary, and converts it to JPEG format for embedding.

Generates HTML files for each certificate listed in the given register
table. It checks for the existence of the certificate PDF, downloads it
if necessary, and converts it to JPEG format for embedding.

## Usage

``` r
render_cert_htmls(register_table, force_download = FALSE)
```

## Arguments

- register_table:

  A data frame containing details of each certificate, including
  repository links and report links.

- force_download:

  Logical; if TRUE, forces the download of certificate PDFs even if they
  already exist locally. Defaults to FALSE.

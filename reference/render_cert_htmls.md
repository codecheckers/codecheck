# Generates HTML files for each certificate listed in the given register table. It checks for the existence of the certificate PDF, downloads it if necessary, and converts it to JPEG format for embedding.

Generates HTML files for each certificate listed in the given register
table. It checks for the existence of the certificate PDF, downloads it
if necessary, and converts it to JPEG format for embedding.

## Usage

``` r
render_cert_htmls(
  register_table,
  force_download = FALSE,
  parallel = FALSE,
  ncores = NULL
)
```

## Arguments

- register_table:

  A data frame containing details of each certificate, including
  repository links and report links.

- force_download:

  Logical; if TRUE, forces the download of certificate PDFs even if they
  already exist locally. Defaults to FALSE.

- parallel:

  Logical; if TRUE, renders certificates in parallel using multiple
  cores. Defaults to FALSE.

- ncores:

  Integer; number of CPU cores to use for parallel rendering. If NULL,
  automatically detects available cores minus 1. Defaults to NULL.

# Retrieves the link to a certificate PDF file from an OSF project node. It retrieves its files, and searches for a single PDF certificate file within the node. If multiple or no PDF files are found, it returns NULL with a warning.

Retrieves the link to a certificate PDF file from an OSF project node.
It retrieves its files, and searches for a single PDF certificate file
within the node. If multiple or no PDF files are found, it returns NULL
with a warning.

## Usage

``` r
get_osf_cert_link(report_link, cert_id)
```

## Arguments

- report_link:

  URL of the OSF report to access.

- cert_id:

  ID of the certificate, used for logging and warnings.

## Value

The download link for the certificate file as a string if a single PDF
is found; otherwise, NULL.

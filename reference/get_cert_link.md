# Retrieves the download link for a certificate file from Zenodo, OSF, or ResearchEquals.

Retrieves the download link for a certificate file from Zenodo, OSF, or
ResearchEquals.

## Usage

``` r
get_cert_link(report_link, cert_id)
```

## Arguments

- report_link:

  URL of the report to access, either from Zenodo, OSF, or
  ResearchEquals.

- cert_id:

  ID of the certificate, used for logging and warnings.

## Value

The download link for the certificate file as a string if found;
otherwise, NULL.

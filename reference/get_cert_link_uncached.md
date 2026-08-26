# Resolves the download link for a certificate file without caching, see get_cert_link().

Resolves the download link for a certificate file without caching, see
get_cert_link().

## Usage

``` r
get_cert_link_uncached(report_link, cert_id)
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

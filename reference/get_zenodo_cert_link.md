# Accesses a codecheck's Zenodo record via its report link, retrieves the record ID, and searches for a certificate PDF or ZIP file within the record's files using the Zenodo API.

Accesses a codecheck's Zenodo record via its report link, retrieves the
record ID, and searches for a certificate PDF or ZIP file within the
record's files using the Zenodo API.

## Usage

``` r
get_zenodo_cert_link(report_link, cert_id, api_key = "")
```

## Arguments

- report_link:

  URL of the Zenodo report to access.

- cert_id:

  ID of the certificate, used for logging and warnings.

- api_key:

  (Optional) API key for Zenodo authentication if required.

## Value

The download link for the certificate file as a string if found;
otherwise, NULL.

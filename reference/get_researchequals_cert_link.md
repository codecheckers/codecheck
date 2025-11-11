# Accesses a codecheck's ResearchEquals record via its report link and download the main file of the module

Accesses a codecheck's ResearchEquals record via its report link and
download the main file of the module

## Usage

``` r
get_researchequals_cert_link(report_link, cert_id)
```

## Arguments

- report_link:

  URL of the ResearchEquals report to access.

- cert_id:

  ID of the certificate, used for logging and warnings.

## Value

The download link for the certificate file as a string if found;
otherwise, NULL.

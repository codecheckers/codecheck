# Downloads a certificate PDF from a report link and saves it locally. If the download link is a ZIP file, it extracts the PDF from the archive. Returns status based on success.

Downloads a certificate PDF from a report link and saves it locally. If
the download link is a ZIP file, it extracts the PDF from the archive.
Returns status based on success.

## Usage

``` r
download_cert_pdf(report_link, cert_id)
```

## Arguments

- report_link:

  URL of the report from which to download the certificate.

- cert_id:

  ID of the certificate, used for directory naming and logging.

## Value

1 if the certificate is successfully downloaded and saved; otherwise, 0.

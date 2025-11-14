# Downloads a ZIP file from the given URL, searches for "codecheck.pdf" within its contents, renames it to "cert.pdf," and saves it in the specified directory.

Downloads a ZIP file from the given URL, searches for "codecheck.pdf"
within its contents, renames it to "cert.pdf," and saves it in the
specified directory.

## Usage

``` r
extract_cert_pdf_from_zip(zip_download_url, cert_sub_dir, cert_id)
```

## Arguments

- zip_download_url:

  URL to download the ZIP file from.

- cert_sub_dir:

  Directory to save the extracted certificate PDF.

- cert_id:

  ID of the certificate, used for logging and warnings.

## Value

1 if "codecheck.pdf" is found and saved, otherwise 0.

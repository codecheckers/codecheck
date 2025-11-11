# Generates a Markdown file for a certificate based on a specified template, filling in details about the paper, authors, codecheck information, and the certificate images if available. The resulting Markdown file is later rendered to HTML.

Generates a Markdown file for a certificate based on a specified
template, filling in details about the paper, authors, codecheck
information, and the certificate images if available. The resulting
Markdown file is later rendered to HTML.

## Usage

``` r
create_cert_md(cert_id, repo_link, download_cert_status)
```

## Arguments

- cert_id:

  A character string representing the unique identifier of the
  certificate.

- repo_link:

  A character string containing the repository link associated with the
  certificate.

- download_cert_status:

  An integer (0 or 1) indicating whether the certificate PDF was
  downloaded (1) or not (0).

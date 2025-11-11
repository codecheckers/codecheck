# Populates an existing markdown content template with details about the codechecked paper.

Populates an existing markdown content template with details about the
codechecked paper.

## Usage

``` r
add_paper_details_md(md_content, repo_link, download_cert_status)
```

## Arguments

- md_content:

  A character string containing the Markdown template content with
  placeholders.

- repo_link:

  A character string containing the repository link associated with the
  certificate.

- download_cert_status:

  An integer (0 or 1) indicating whether the certificate PDF was
  downloaded (1) or not (0).

## Value

The markdown content, with paper details placeholders filled.

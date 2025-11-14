# Populates an existing markdown content template with details about the CODECHECK details.

Populates an existing markdown content template with details about the
CODECHECK details.

## Usage

``` r
add_codecheck_details_md(md_content, repo_link, cert_type, cert_venue)
```

## Arguments

- md_content:

  A character string containing the Markdown template content with
  placeholders.

- repo_link:

  A character string containing the repository link associated with the
  certificate.

- cert_type:

  A character string containing the venue type (journal, conference,
  community, institution).

- cert_venue:

  A character string containing the venue name.

## Value

The markdown content, with CODECHECK details placeholders filled.

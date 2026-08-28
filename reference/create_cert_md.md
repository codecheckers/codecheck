# Generates a Markdown file for a certificate based on a specified template, filling in details about the paper, authors, codecheck information, and the certificate images if available. The resulting Markdown file is later rendered to HTML.

Generates a Markdown file for a certificate based on a specified
template, filling in details about the paper, authors, codecheck
information, and the certificate images if available. The resulting
Markdown file is later rendered to HTML.

## Usage

``` r
create_cert_md(
  cert_id,
  repo_link,
  download_cert_status,
  cert_type,
  cert_venue,
  openalex_id = NULL,
  abstract_data = NULL
)
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

- cert_type:

  A character string containing the venue type (journal, conference,
  community, institution).

- cert_venue:

  A character string containing the venue name.

- openalex_id:

  Optional pre-resolved OpenAlex ID (see
  [`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md));
  when \`NULL\`, looked up here directly.

- abstract_data:

  Optional pre-resolved abstract; when \`NULL\`, looked up here
  directly.

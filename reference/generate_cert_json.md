# Generates a JSON file with all certificate metadata

Creates an index.json file containing all information displayed on the
certificate landing page for programmatic access.

## Usage

``` r
generate_cert_json(
  cert_id,
  repo_link,
  cert_type,
  cert_venue,
  openalex_id = NULL,
  abstract_data = NULL,
  cert_title = NULL
)
```

## Arguments

- cert_id:

  A character string representing the unique identifier of the
  certificate.

- repo_link:

  A character string containing the repository link associated with the
  certificate.

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

- cert_title:

  Optional pre-resolved title of the certificate's record on its
  publication platform; when \`NULL\`, looked up here directly, see
  [`resolve_cert_title`](http://codecheck.org.uk/codecheck/reference/resolve_cert_title.md).

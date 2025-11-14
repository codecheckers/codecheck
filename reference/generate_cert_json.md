# Generates a JSON file with all certificate metadata

Creates an index.json file containing all information displayed on the
certificate landing page for programmatic access.

## Usage

``` r
generate_cert_json(cert_id, repo_link, cert_type, cert_venue)
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

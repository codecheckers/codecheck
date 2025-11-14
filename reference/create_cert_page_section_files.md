# Generates section files for a certificate HTML page, including prefix, postfix, and header HTML components.

Generates section files for a certificate HTML page, including prefix,
postfix, and header HTML components.

## Usage

``` r
create_cert_page_section_files(
  output_dir,
  cert_id = NULL,
  cert_type = NULL,
  cert_venue = NULL,
  repo_link = NULL
)
```

## Arguments

- output_dir:

  A character string specifying the directory where the section files
  will be saved.

- cert_id:

  The certificate identifier for breadcrumb generation

- cert_type:

  The venue type (journal, conference, community, institution) for
  breadcrumb generation

- cert_venue:

  The venue name for breadcrumb generation

- repo_link:

  Repository link to fetch codecheck.yml for Schema.org metadata
  generation (default: NULL)

# Populates an existing markdown content template with details about the codechecked paper.

Populates an existing markdown content template with details about the
codechecked paper.

## Usage

``` r
add_paper_details_md(
  md_content,
  repo_link,
  openalex_id = NULL,
  abstract_data = NULL
)
```

## Arguments

- md_content:

  A character string containing the Markdown template content with
  placeholders.

- repo_link:

  A character string containing the repository link associated with the
  certificate.

- openalex_id:

  Optional pre-resolved OpenAlex ID; when \`NULL\`, looked up here
  directly.

- abstract_data:

  Optional pre-resolved abstract; when \`NULL\`, looked up here
  directly.

## Value

The markdown content, with paper details placeholders filled.

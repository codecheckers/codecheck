# Inserts the abstract text and source link into the Markdown content if an abstract is found for the given repository. If no abstract is found, an empty string is inserted in place of the abstract content.

Inserts the abstract text and source link into the Markdown content if
an abstract is found for the given repository. If no abstract is found,
an empty string is inserted in place of the abstract content.

## Usage

``` r
add_abstract(repo_link, md_content, abstract_data = NULL)
```

## Arguments

- repo_link:

  A character string containing the repository link from which to
  retrieve the abstract.

- md_content:

  A character string containing the Markdown content with placeholders
  for abstract details.

- abstract_data:

  Optional pre-resolved abstract (list with \`source\`/\`text\`, see
  [`resolve_external_field`](http://codecheck.org.uk/codecheck/reference/resolve_external_field.md));
  when \`NULL\`, looked up here directly.

## Value

The markdown content with filled abstract placeholder

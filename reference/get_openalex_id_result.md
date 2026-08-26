# Look up the OpenAlex work ID and report whether the answer is conclusive

Same lookup as
[`get_openalex_id`](http://codecheck.org.uk/codecheck/reference/get_openalex_id.md),
but distinguishes an ID that OpenAlex does not have from a request that
did not succeed, so that only the former is cached, see
[`cached_lookup`](http://codecheck.org.uk/codecheck/reference/cached_lookup.md).

## Usage

``` r
get_openalex_id_result(
  paper_reference,
  paper_title = NULL,
  first_author_name = NULL
)
```

## Arguments

- paper_reference:

  The paper reference URL (typically a DOI URL)

- paper_title:

  Optional paper title for fallback search

- first_author_name:

  Optional first author name for fallback search

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`

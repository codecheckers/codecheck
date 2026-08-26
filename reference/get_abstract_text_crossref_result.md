# Retrieves the abstract from CrossRef and reports whether the API answered

Retrieves the abstract from CrossRef and reports whether the API
answered

## Usage

``` r
get_abstract_text_crossref_result(register_repo)
```

## Arguments

- register_repo:

  URL or path to the repository containing the paper's configuration.

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`,
the abstract text as a string or NULL

# Retrieves the abstract of a research paper from CrossRef or OpenAlex.

This function attempts to retrieve a paper's abstract using the
OpenAlex. API first. If that fails it then attempts to retrieve from
CrossRef

## Usage

``` r
get_abstract(register_repo)
```

## Arguments

- register_repo:

  URL or path to the repository containing the paper's configuration.

## Value

A list with two elements: \`source\` (indicating "CrossRef" or
"OpenAlex" if found) and \`text\` (the abstract text as a string, or
NULL if unavailable).

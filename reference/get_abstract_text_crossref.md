# Extracts the paper DOI from the config_yml of the paper, constructs a CrossRef API request, and returns the abstract text if available.

Extracts the paper DOI from the config_yml of the paper, constructs a
CrossRef API request, and returns the abstract text if available.

## Usage

``` r
get_abstract_text_crossref(register_repo)
```

## Arguments

- register_repo:

  URL or path to the repository containing the paper's configuration.

## Value

The abstract text as a string if available; otherwise, NULL.

# Look up the OpenAlex work ID for a paper reference URL

Queries the OpenAlex API by DOI. If the DOI lookup fails, falls back to
a title search filtered by first author name (accepts only a single
exact match).

## Usage

``` r
get_openalex_id(paper_reference, paper_title = NULL, first_author_name = NULL)
```

## Arguments

- paper_reference:

  The paper reference URL (typically a DOI URL)

- paper_title:

  Optional paper title for fallback search

- first_author_name:

  Optional first author name for fallback search

## Value

The OpenAlex work URL (e.g., "https://openalex.org/W1234567890") or
NA_character\_

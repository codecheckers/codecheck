# Retrieve a collection on ResearchEquals

Retrieve a collection from ResearchEquals

## Usage

``` r
get_researchequals_collection(
  issue_id = RESEARCHEQUALS_COLLECTIONS[[1]]$issue_id
)
```

## Arguments

- issue_id:

  the collection issue ID, defaults to the current CODECHECK issue

## Value

the parsed API response as a list, with the element \`submissions\`

## Details

Fetches the issue of a collection, including the list of submissions
that constitutes its membership.

## Author

Daniel Nuest

# Generate redirect pages for all codecheckers with ORCID

Iterates through all codecheckers in the register and creates redirect
pages for those who have both ORCID and GitHub handle. The redirect
pages are created at the GitHub handle URL and redirect to the
ORCID-based URL.

## Usage

``` r
generate_codechecker_redirects(register_table)
```

## Arguments

- register_table:

  The preprocessed register table

## Value

Invisibly returns the count of redirect pages created

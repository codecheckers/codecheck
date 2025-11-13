# Generate HTML for codechecker profile links

Creates a horizontal list of profile links (ORCID, GitHub) for a
codechecker page. Uses a template file to generate the HTML.

## Usage

``` r
generate_codechecker_profile_links(orcid)
```

## Arguments

- orcid:

  The ORCID identifier

## Value

HTML string with profile links, or empty string if no profile found

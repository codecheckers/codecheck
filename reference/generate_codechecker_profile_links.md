# Generate HTML for codechecker profile links

Creates a horizontal list of profile links (ORCID, GitHub) for a
codechecker page. Uses a template file to generate the HTML. Supports
both ORCID and handle-based identifiers.

## Usage

``` r
generate_codechecker_profile_links(identifier)
```

## Arguments

- identifier:

  The codechecker identifier (ORCID or "handle:username")

## Value

HTML string with profile links, or empty string if no profile found

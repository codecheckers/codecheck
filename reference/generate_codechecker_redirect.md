# Generate HTML redirect page for codechecker

Creates a redirect page at the GitHub handle URL that redirects to the
ORCID-based page. This is used for codecheckers who have both ORCID and
GitHub handle.

## Usage

``` r
generate_codechecker_redirect(github_handle, orcid, name)
```

## Arguments

- github_handle:

  The GitHub handle (without @ prefix)

- orcid:

  The ORCID identifier

- name:

  The codechecker's name

## Value

Invisibly returns TRUE if successful, FALSE otherwise

# Get GitHub handle for a codechecker by name

Looks up the GitHub handle for a codechecker by their name in all three
codechecker lists, see \[all_codechecker_records()\]. Used for
codecheckers whose \`codecheck.yml\` carries no ORCID, where the name is
all there is to match on.

## Usage

``` r
get_github_handle_by_name(name)
```

## Arguments

- name:

  The full name of the codechecker

## Value

The GitHub handle (without @ prefix) or NULL if not found

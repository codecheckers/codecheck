# Get git repository information

Get git repository information

## Usage

``` r
get_git_info(path = getwd())
```

## Arguments

- path:

  Path to check for git repository (defaults to current working
  directory)

## Value

A character string with commit information, or empty string if not in a
git repo

## Details

Returns a formatted string with git commit information if the path is in
a git repository, otherwise returns an empty string. This is used in
certificate templates to document which commit was checked.

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # In a git repository
  get_git_info(".")
  # Returns: "This check is based on the commit `abc123...`."

  # Not in a git repository
  get_git_info("/tmp")
  # Returns: ""
} # }
```

# Retrieve repository metadata from the GitHub API

Thin wrapper around the repo endpoint so callers (and tests, via
\`with_mocked_codecheck()\`) only need to deal with the fields they use,
e.g. \`archived\` and \`license\`.

## Usage

``` r
get_github_repo_metadata(repo)
```

## Arguments

- repo:

  the \`org/repo\` or \`org/repo\|path\` spec

## Value

the parsed API response, or \`NULL\` if the repository could not be
retrieved

## Author

Daniel Nuest

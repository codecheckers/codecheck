# Get Build Metadata

Retrieves metadata about the current build including timestamp, package
version, and git commit information from both the register and codecheck
package repositories.

## Usage

``` r
get_build_metadata(register_repo_path = ".", codecheck_repo_path = NULL)
```

## Arguments

- register_repo_path:

  Path to the register repository (default: current directory)

- codecheck_repo_path:

  Optional path to the codecheck package repository (default: NULL, will
  attempt to find it)

## Value

A list with build metadata including commits from both repositories

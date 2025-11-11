# Update certificate ID from GitHub issue

Update certificate ID from GitHub issue

## Usage

``` r
update_certificate_from_github(
  yml_file = "codecheck.yml",
  issue_state = "open",
  force = FALSE,
  apply_update = FALSE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- issue_state:

  State of issues to search: "open" (default), "closed", or "all"

- force:

  Logical. If TRUE, update even if certificate is not a placeholder.
  Default is FALSE.

- apply_update:

  Logical. If TRUE, actually update the file. If FALSE (default), only
  show what would be changed.

## Value

Invisibly returns a list with:

- updated:

  Logical indicating if file was updated

- certificate:

  The certificate ID (if found)

- issue_number:

  The GitHub issue number (if found)

- was_placeholder:

  Logical indicating if original was a placeholder

## Details

Automatically retrieves and updates the certificate identifier from a
GitHub issue. This function checks if the current certificate is a
placeholder, searches for matching GitHub issues, and if a unique match
is found, updates the codecheck.yml file with the certificate ID.

The function provides detailed logging of all steps and will only update
the file if exactly one matching issue is found (to avoid ambiguity).

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Preview what would be updated
  result <- update_certificate_from_github()

  # Actually update the file
  update_certificate_from_github(apply_update = TRUE)

  # Force update even if not a placeholder
  update_certificate_from_github(force = TRUE, apply_update = TRUE)
} # }
```

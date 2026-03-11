# Validate certificate identifier exists in GitHub register issues

Checks if the certificate identifier from a codecheck.yml file has a
corresponding issue in the codecheckers/register GitHub repository. This
function validates that:

- A matching issue exists for the certificate identifier

- Warns if the issue is closed (certificate already completed)

- Warns if the issue is unassigned (no codechecker assigned yet)

- Stops with error if no matching issue is found

## Usage

``` r
validate_certificate_github_issue(
  yml_file = "codecheck.yml",
  metadata = NULL,
  repo = "codecheckers/register",
  strict = FALSE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- metadata:

  Optional. Pre-loaded metadata list. If NULL, will be loaded from
  yml_file

- repo:

  GitHub repository in format "owner/repo". Defaults to
  "codecheckers/register"

- strict:

  Logical. If TRUE, treats warnings as errors. Default is FALSE

## Value

Invisibly returns a list with the validation result:

- valid:

  Logical indicating if validation passed

- certificate:

  The certificate identifier checked

- issue_number:

  GitHub issue number if found, otherwise NULL

- issue_state:

  Issue state ("open" or "closed") if found

- issue_assignees:

  List of assignees if found

- warnings:

  Character vector of warning messages

- errors:

  Character vector of error messages

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
# Validate certificate in current directory
validate_certificate_github_issue()

# Validate with strict mode (warnings become errors)
validate_certificate_github_issue(strict = TRUE)

# Validate specific file
validate_certificate_github_issue("path/to/codecheck.yml")
} # }
```

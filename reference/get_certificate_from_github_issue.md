# Get certificate identifier from GitHub issues by matching author names

This function retrieves open issues from the codecheckers/register
repository and attempts to match author names from a codecheck.yml file
with issue titles to find the corresponding certificate identifier.

## Usage

``` r
get_certificate_from_github_issue(
  yml_file,
  repo = "codecheckers/register",
  state = "open",
  max_issues = 100
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file, or a list with codecheck metadata

- repo:

  GitHub repository in the format "owner/repo". Defaults to
  "codecheckers/register"

- state:

  Issue state to search. One of "open", "closed", or "all". Defaults to
  "open"

- max_issues:

  Maximum number of issues to retrieve. Defaults to 100

## Value

A list with the following elements:

- certificate: The certificate identifier (e.g., "2025-028") if found,
  otherwise NULL

- issue_number: The GitHub issue number if found, otherwise NULL

- issue_title: The full issue title if found, otherwise NULL

- matched_author: The author name that was matched, otherwise NULL

## Details

Issue titles in the register follow the format: "Author Last, Author
First \| YYYY-NNN" where YYYY-NNN is the certificate identifier.

## Author

Daniel Nüst

## Examples

``` r
if (FALSE) { # \dontrun{
# Get certificate ID from open issues
result <- get_certificate_from_github_issue("codecheck.yml")
if (!is.null(result$certificate)) {
  cat("Found certificate:", result$certificate, "in issue", result$issue_number, "\n")
}

# Search closed issues
result <- get_certificate_from_github_issue("codecheck.yml", state = "closed")

# Pass metadata directly
metadata <- codecheck_metadata(".")
result <- get_certificate_from_github_issue(metadata)
} # }
```

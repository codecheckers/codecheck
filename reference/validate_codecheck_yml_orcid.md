# Validate codecheck.yml metadata against ORCID

Validate codecheck.yml metadata against ORCID

## Usage

``` r
validate_codecheck_yml_orcid(
  yml_file = "codecheck.yml",
  strict = FALSE,
  validate_authors = TRUE,
  validate_codecheckers = TRUE,
  skip_on_auth_error = FALSE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- strict:

  Logical. If `TRUE`, throw an error on any mismatch. If `FALSE`
  (default), only issue warnings.

- validate_authors:

  Logical. If `TRUE` (default), validate author ORCIDs.

- validate_codecheckers:

  Logical. If `TRUE` (default), validate codechecker ORCIDs.

- skip_on_auth_error:

  Logical. If `TRUE`, skip validation when ORCID authentication fails
  instead of throwing an error. Default is `FALSE`, which requires ORCID
  authentication. Set to `TRUE` to allow the function to work without
  ORCID authentication (e.g., CI/CD pipelines, test environments).

## Value

Invisibly returns a list with validation results:

- valid:

  Logical indicating if all checks passed

- issues:

  Character vector of any issues found

- skipped:

  Logical indicating if validation was skipped due to auth issues

## Details

Validates author and codechecker information against the ORCID API. For
each person with an ORCID, retrieves their ORCID record and compares the
name in the ORCID record with the name in the local codecheck.yml file.

Note: This function requires access to the ORCID API. If you encounter
authentication issues, you can either:

- Set the `ORCID_TOKEN` environment variable with your ORCID token

- Run
  [`rorcid::orcid_auth()`](https://rdrr.io/pkg/rorcid/man/orcid_auth.html)
  to authenticate interactively

- Set `skip_on_auth_error = TRUE` to skip validation if authentication
  fails

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Validate with warnings only (requires ORCID authentication)
  result <- validate_codecheck_yml_orcid()

  # Validate with strict error checking
  validate_codecheck_yml_orcid(strict = TRUE)

  # Validate only codecheckers
  validate_codecheck_yml_orcid(validate_authors = FALSE)

  # Skip ORCID validation if authentication is not available
  validate_codecheck_yml_orcid(skip_on_auth_error = TRUE)
} # }
```

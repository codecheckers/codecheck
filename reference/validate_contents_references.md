# Validate codecheck.yml metadata against external references

Validate codecheck.yml metadata against external references

## Usage

``` r
validate_contents_references(
  yml_file = "codecheck.yml",
  strict = FALSE,
  validate_crossref = TRUE,
  validate_orcid = TRUE,
  check_orcids = TRUE,
  skip_on_auth_error = FALSE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- strict:

  Logical. If `TRUE`, throw an error on any mismatch. If `FALSE`
  (default), only issue warnings.

- validate_crossref:

  Logical. If `TRUE` (default), validate against CrossRef.

- validate_orcid:

  Logical. If `TRUE` (default), validate against ORCID.

- check_orcids:

  Logical. If `TRUE` (default), validate ORCID identifiers in CrossRef
  check.

- skip_on_auth_error:

  Logical. If `TRUE`, skip ORCID validation when authentication fails
  instead of throwing an error. Default is `FALSE`, which requires ORCID
  authentication. Set to `TRUE` to allow the function to work without
  ORCID authentication (e.g., CI/CD pipelines, test environments).

## Value

Invisibly returns a list with validation results:

- valid:

  Logical indicating if all checks passed

- crossref_result:

  Results from CrossRef validation (if performed)

- orcid_result:

  Results from ORCID validation (if performed)

## Details

Wrapper function that validates codecheck.yml metadata against both
CrossRef (for paper metadata) and ORCID (for author and codechecker
information). This provides comprehensive validation of all external
references.

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Validate everything with warnings only
  result <- validate_contents_references()

  # Validate with strict error checking
  validate_contents_references(strict = TRUE)

  # Validate only CrossRef
  validate_contents_references(validate_orcid = FALSE)

  # Validate only ORCID
  validate_contents_references(validate_crossref = FALSE)

  # Skip ORCID validation if authentication is not available
  validate_contents_references(skip_on_auth_error = TRUE)
} # }
```

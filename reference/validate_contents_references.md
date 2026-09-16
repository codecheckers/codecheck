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
  (default), a rule failed at severity error still stops, after both
  validations have run.

- validate_crossref:

  Logical. If `TRUE` (default), validate against CrossRef.

- validate_orcid:

  Logical. If `TRUE` (default), validate against ORCID.

- check_orcids:

  Logical. If `TRUE` (default), validate ORCID identifiers in CrossRef
  check.

- skip_on_auth_error:

  Deprecated and without effect: an ORCID record that cannot be
  retrieved is always skipped.

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
} # }
```

# Validate codecheck.yml metadata against CrossRef

Validate codecheck.yml metadata against CrossRef

## Usage

``` r
validate_codecheck_yml_crossref(
  yml_file = "codecheck.yml",
  strict = FALSE,
  check_orcids = TRUE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- strict:

  Logical. If `TRUE`, throw an error on any mismatch. If `FALSE`
  (default), only issue warnings.

- check_orcids:

  Logical. If `TRUE` (default), validate ORCID identifiers. If `FALSE`,
  skip ORCID validation.

## Value

Invisibly returns a list with validation results:

- valid:

  Logical indicating if all checks passed

- issues:

  Character vector of any issues found

- crossref_metadata:

  The metadata retrieved from CrossRef (if available)

## Details

Retrieves metadata from CrossRef for the paper's DOI and compares it
with the local codecheck.yml metadata. Validates title and author
information (names and ORCIDs against CrossRef data).

This function is useful for ensuring consistency between the published
paper metadata and the CODECHECK certificate, helping to catch typos,
outdated information, or missing data.

Note: For comprehensive validation including ORCID name verification and
codechecker validation, use
[`validate_contents_references()`](http://codecheck.org.uk/codecheck/reference/validate_contents_references.md)
instead.

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Validate with warnings only
  result <- validate_codecheck_yml_crossref()

  # Validate with strict error checking
  validate_codecheck_yml_crossref(strict = TRUE)

  # Skip ORCID validation
  validate_codecheck_yml_crossref(check_orcids = FALSE)
} # }
```

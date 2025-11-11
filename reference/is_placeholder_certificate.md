# Check if certificate identifier or DOI is a placeholder

Determines whether a certificate identifier or report DOI in
codecheck.yml is a placeholder that needs to be replaced. Checks for
common placeholder patterns like "YYYY-NNN", "0000-000", or placeholder
year prefixes in certificate ID, and "FIXME", "TODO", etc. in the report
DOI.

## Usage

``` r
is_placeholder_certificate(
  yml_file = "codecheck.yml",
  metadata = NULL,
  strict = FALSE,
  check_doi = TRUE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- metadata:

  Optional metadata list. If NULL (default), loads from yml_file.

- strict:

  Logical. If TRUE and certificate or DOI is a placeholder, stops
  execution with an error. Default is FALSE (returns TRUE/FALSE without
  stopping).

- check_doi:

  Logical. If TRUE (default), also checks the report DOI field for
  placeholder patterns.

## Value

Logical value: TRUE if certificate or DOI is a placeholder, FALSE
otherwise. If strict=TRUE and either is a placeholder, stops with an
error instead.

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Check if certificate or DOI is a placeholder
  if (is_placeholder_certificate()) {
    message("Certificate ID or DOI needs to be set")
  }

  # Check specific file
  is_placeholder_certificate("path/to/codecheck.yml")

  # Only check certificate, not DOI
  is_placeholder_certificate(check_doi = FALSE)

  # Fail if certificate or DOI is a placeholder
  is_placeholder_certificate(strict = TRUE)
} # }
```

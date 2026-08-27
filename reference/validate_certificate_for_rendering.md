# Validate certificate for rendering with visual warning

Validate certificate for rendering and display warning if placeholder

## Usage

``` r
validate_certificate_for_rendering(
  yml_file = "codecheck.yml",
  metadata = NULL,
  strict = FALSE,
  display_warning = TRUE,
  check_concept_doi = TRUE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- metadata:

  Optional metadata list. If NULL (default), loads from yml_file.

- strict:

  Logical. If TRUE and certificate or DOI is a placeholder, stops
  execution. Default is FALSE (displays warning but continues).

- display_warning:

  Logical. If TRUE (default), displays a warning box in the rendered
  output when certificate or DOI is a placeholder.

- check_concept_doi:

  Logical. If TRUE (default), checks whether a Zenodo report DOI is a
  concept DOI (which always resolves to the latest version) rather than
  a version-specific DOI, and warns if so. Requires a network request to
  Zenodo; if that request fails (e.g. offline rendering), the check is
  silently skipped rather than failing the render.

## Value

Invisibly returns TRUE if certificate and DOI are valid, FALSE if any
placeholder

## Details

This function checks if the certificate identifier and report DOI are
placeholders, or the report DOI is a Zenodo concept DOI instead of a
version-specific DOI (see \#36), and prints a LaTeX warning box with a
warning icon if so. Intended for use in R Markdown or Quarto templates
to alert users about placeholder certificates and DOIs.

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # In an R Markdown template, use in a chunk:
  validate_certificate_for_rendering()

  # Fail rendering if certificate or DOI is a placeholder:
  validate_certificate_for_rendering(strict = TRUE)
} # }
```

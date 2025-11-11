# Validate certificate for rendering with visual warning

Validate certificate for rendering and display warning if placeholder

## Usage

``` r
validate_certificate_for_rendering(
  yml_file = "codecheck.yml",
  metadata = NULL,
  strict = FALSE,
  display_warning = TRUE
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

## Value

Invisibly returns TRUE if certificate and DOI are valid, FALSE if any
placeholder

## Details

This function checks if the certificate identifier and report DOI are
placeholders and prints a LaTeX warning box with a warning icon if they
are. Intended for use in R Markdown templates to alert users about
placeholder certificates and DOIs.

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

# Analyze and complete codecheck.yml with missing fields

Analyze and complete codecheck.yml with missing fields

## Usage

``` r
complete_codecheck_yml(
  yml_file = "codecheck.yml",
  add_mandatory = FALSE,
  add_optional = FALSE,
  apply_updates = FALSE
)
```

## Arguments

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- add_mandatory:

  Logical. If `TRUE`, add placeholders for all missing mandatory fields.
  Default is `FALSE`.

- add_optional:

  Logical. If `TRUE`, add placeholders for all missing optional and
  recommended fields. Default is `FALSE`.

- apply_updates:

  Logical. If `TRUE`, actually update the file. If `FALSE` (default),
  only show what would be changed.

## Value

Invisibly returns a list with two elements:

- missing:

  List of missing fields by category (mandatory, recommended, optional)

- updated:

  The updated metadata list (if changes were made)

## Details

Analyzes a codecheck.yml file to identify missing mandatory and optional
fields according to the CODECHECK specification
(https://codecheck.org.uk/spec/config/1.0/). Can add placeholders for
missing fields. By default, shows what would be changed without actually
modifying the file.

The function identifies three categories of fields:

- **Mandatory fields**: manifest, codechecker, report

- **Recommended fields**: version, paper (title, authors, reference)

- **Optional fields**: source, summary, repository, check_time,
  certificate

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Analyze current codecheck.yml
  result <- complete_codecheck_yml()

  # Add mandatory fields only
  complete_codecheck_yml(add_mandatory = TRUE, apply_updates = TRUE)

  # Add all missing fields
  complete_codecheck_yml(add_mandatory = TRUE, add_optional = TRUE,
                         apply_updates = TRUE)
} # }
```

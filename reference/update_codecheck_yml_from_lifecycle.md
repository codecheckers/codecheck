# Update codecheck.yml with Lifecycle Journal metadata

Update codecheck.yml with Lifecycle Journal metadata

## Usage

``` r
update_codecheck_yml_from_lifecycle(
  identifier,
  yml_file = "codecheck.yml",
  apply_updates = FALSE,
  overwrite_existing = FALSE
)
```

## Arguments

- identifier:

  Either a Lifecycle Journal submission ID or DOI

- yml_file:

  Path to the codecheck.yml file (defaults to "./codecheck.yml")

- apply_updates:

  Logical. If `TRUE`, actually update the file. If `FALSE` (default),
  only show what would be changed.

- overwrite_existing:

  Logical. If `TRUE`, overwrite existing non-empty fields. If `FALSE`
  (default), only populate empty or placeholder fields.

## Value

Invisibly returns the updated metadata list

## Details

Updates the local codecheck.yml file with metadata retrieved from the
Lifecycle Journal. By default, shows a diff of what would be changed
without actually modifying the file. Use `apply_updates = TRUE` to apply
the changes.

## Author

Daniel Nuest

## Examples

``` r
if (FALSE) { # \dontrun{
  # Preview changes without applying them
  update_codecheck_yml_from_lifecycle("10")

  # Apply changes to the file
  update_codecheck_yml_from_lifecycle("10", apply_updates = TRUE)

  # Overwrite existing fields
  update_codecheck_yml_from_lifecycle("10", apply_updates = TRUE,
                                       overwrite_existing = TRUE)
} # }
```

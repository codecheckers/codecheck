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

  Logical. If `TRUE`, skip validation for a record when both the
  authenticated ORCID lookup and the public API fallback fail, instead
  of throwing an error. Default is `FALSE`. Most records are still
  validated via the public API fallback regardless of this setting; this
  only controls behavior once both lookups fail.

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

Note: Name lookups first try the authenticated ORCID API
([`orcid_person`](https://rdrr.io/pkg/rorcid/man/orcid_person.html)),
then automatically fall back to the public, unauthenticated ORCID API
for records whose name is publicly visible. Personal ORCID
authentication (`ORCID_TOKEN` or
[`rorcid::orcid_auth()`](https://rdrr.io/pkg/rorcid/man/orcid_auth.html))
only ever authorizes reading the authenticated user's own record, so it
cannot help validate a co-author's or a different codechecker's ORCID -
the public fallback is what makes those lookups work. If both the
authenticated lookup and the public fallback fail (e.g. no network
access, or the record's name is not public), you can either:

- Set `skip_on_auth_error = TRUE` to skip validation for that record

- Verify the ORCID is correct and its name is public

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

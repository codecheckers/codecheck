# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Overview

The `codecheck` package is an R package that assists in conducting
[CODECHECKs](https://codecheck.org.uk/) - independent verification of
computational research. It provides two main functions:

1.  **Workspace creation tools** - Help researchers prepare CODECHECK
    workspaces with proper metadata and structure
2.  **Register management tools** - Render and maintain the [CODECHECK
    Register](https://codecheck.org.uk/register/) which tracks all
    completed codechecks

## Installation & Development

Install the package:

``` r
remotes::install_github("codecheckers/codecheck")
```

Run tests using `tinytest`:

**⚠️ CRITICAL: ALWAYS use `build_install_test()` for testing this
package!**

``` r
# CORRECT: Build, install, and test in a fresh environment
tinytest::build_install_test(".")
```

**DO NOT use `test_all()` from the source directory** - it will cause
test failures because the package functions won’t be properly loaded.
The error “could not find function X” indicates you’re using the wrong
test method.

``` r
# WRONG - DO NOT USE: Will cause "could not find function" errors
tinytest::test_all(".")  # ❌ DON'T DO THIS

# For interactive testing of specific functions during development:
# 1. First install the package: devtools::install()
# 2. Then load it: library(codecheck)
# 3. Then test interactively or source specific test files
```

The package uses GitHub Actions for CI/CD. Check
`.github/workflows/R-CMD-check.yaml` for the automated testing setup.

### Changelog Management

**IMPORTANT**: When making changes to the package, always update
`NEWS.md` with: - A brief description of the change - For new features,
document the user-facing functionality - For bug fixes, reference the
issue or describe the problem solved - For breaking changes, clearly
mark them as such

When bumping the version in `DESCRIPTION`, add a new section to
`NEWS.md` with the version number and date. Follow the existing format
with `# codecheck X.Y.Z` headers.

## Core Architecture

### 1. Workspace Creation (R/codecheck.R)

**Main entry point**:
[`create_codecheck_files()`](http://codecheck.org.uk/codecheck/reference/create_codecheck_files.md)
creates the initial CODECHECK workspace including:

- A `codecheck.yml` file with required metadata (certificate ID,
  authors, manifest, etc.)
- A `codecheck/` directory with report templates

**Key functions**:

- [`codecheck_metadata()`](http://codecheck.org.uk/codecheck/reference/codecheck_metadata.md) -
  Load and parse `codecheck.yml`
- [`copy_manifest_files()`](http://codecheck.org.uk/codecheck/reference/copy_manifest_files.md) -
  Copy output files specified in the manifest to the codecheck folder
- [`validate_yaml_syntax()`](http://codecheck.org.uk/codecheck/reference/validate_yaml_syntax.md) -
  Validate YAML syntax before parsing; checks if file is valid YAML;
  integrated into certificate template to prevent compilation with
  invalid YAML (R/configuration.R:184)
- [`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md) -
  Validate that a codecheck.yml file meets the specification
  (R/configuration.R:348)
- [`complete_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/complete_codecheck_yml.md) -
  Analyze and complete codecheck.yml with missing fields; validates
  against specification; can add placeholders for mandatory and optional
  fields
- [`validate_codecheck_yml_crossref()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml_crossref.md) -
  Validate metadata against CrossRef; checks title, authors, and ORCID
  consistency; integrated into certificate template
- [`get_certificate_from_github_issue()`](http://codecheck.org.uk/codecheck/reference/get_certificate_from_github_issue.md) -
  Retrieve certificate identifier from GitHub issues by matching author
  names; searches codecheckers/register repository; supports
  open/closed/all issues (R/configuration.R:229)
- [`is_placeholder_certificate()`](http://codecheck.org.uk/codecheck/reference/is_placeholder_certificate.md) -
  Check if certificate ID is a placeholder; detects common placeholder
  patterns and template-like text
- [`update_certificate_from_github()`](http://codecheck.org.uk/codecheck/reference/update_certificate_from_github.md) -
  Automatically update certificate ID from GitHub; wraps
  [`get_certificate_from_github_issue()`](http://codecheck.org.uk/codecheck/reference/get_certificate_from_github_issue.md)
  with placeholder detection and file updating; integrated into
  certificate template

**Lifecycle Journal automation**: Functions for auto-populating metadata
from Lifecycle Journal articles:

- [`get_lifecycle_metadata()`](http://codecheck.org.uk/codecheck/reference/get_lifecycle_metadata.md) -
  Retrieve article metadata from CrossRef API using submission ID or DOI
  (prefix: `10.71240/lcyc.`)
- [`update_codecheck_yml_from_lifecycle()`](http://codecheck.org.uk/codecheck/reference/update_codecheck_yml_from_lifecycle.md) -
  Update local `codecheck.yml` with metadata; shows diff before applying
  changes; supports preview mode and selective field updates

**External validation**: Ensure consistency with published paper
metadata and ORCID records:

- [`validate_codecheck_yml_crossref()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml_crossref.md) -
  Validates paper metadata against CrossRef API; compares title and
  author information with CrossRef data
- [`validate_codecheck_yml_orcid()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml_orcid.md) -
  Validates author and codechecker names against ORCID API; queries
  ORCID records using rorcid package; compares names in ORCID records
  with local metadata; requires ORCID authentication by default (set
  `skip_on_auth_error = TRUE` to skip validation when authentication is
  unavailable)
- [`validate_contents_references()`](http://codecheck.org.uk/codecheck/reference/validate_contents_references.md) -
  Comprehensive validation wrapper; runs both CrossRef and ORCID
  validations; provides unified summary; supports strict mode for
  certificate rendering; requires ORCID authentication by default (users
  can opt-in to skipping via `skip_on_auth_error = TRUE`)

**Zenodo integration**: Functions for uploading certificates to Zenodo:

- [`get_or_create_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/get_or_create_zenodo_record.md) -
  Create or retrieve a Zenodo record; defaults to loading metadata from
  codecheck.yml in current directory
- [`get_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/get_zenodo_record.md) -
  Retrieve existing Zenodo record; defaults to loading metadata from
  codecheck.yml in current directory
- [`upload_zenodo_metadata()`](http://codecheck.org.uk/codecheck/reference/upload_zenodo_metadata.md) -
  Upload metadata from codecheck.yml; defaults to loading from current
  directory
- [`set_zenodo_certificate()`](http://codecheck.org.uk/codecheck/reference/upload_zenodo_certificate.md) -
  Upload the PDF certificate
- [`get_zenodo_id()`](http://codecheck.org.uk/codecheck/reference/get_zenodo_id.md) -
  Extract Zenodo record number from DOI URL

### 2. Register Management (R/register.R)

**Main entry point**:
[`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
processes a CSV register file and generates multiple views:

- HTML pages for each certificate
- Markdown summaries
- JSON data files
- Filtered views by venue, codechecker, etc.

**Architecture flow**:

1.  Load register CSV and config files (inst/extdata/config.R contains
    global CONFIG)
2.  [`preprocess_register()`](http://codecheck.org.uk/codecheck/reference/preprocess_register.md)
    enriches entries with remote codecheck.yml data
    (R/utils_preprocess_register.R)
3.  Generate outputs:
    - [`render_cert_htmls()`](http://codecheck.org.uk/codecheck/reference/render_cert_htmls.md) -
      HTML certificate pages (R/utils_render_cert_htmls.R)
    - [`create_filtered_reg_csvs()`](http://codecheck.org.uk/codecheck/reference/create_filtered_reg_csvs.md) -
      CSV files filtered by venue/codechecker
      (R/utils_create_filtered_register_csvs.R)
    - [`create_register_files()`](http://codecheck.org.uk/codecheck/reference/create_register_files.md) -
      Main register tables (R/utils_render_register_mds.R,
      R/utils_render_register_htmls.R, R/utils_render_register_json.R)
    - [`create_non_register_files()`](http://codecheck.org.uk/codecheck/reference/create_non_register_files.md) -
      Lists of venues/codecheckers (R/utils_render_table\_\*.R)

**Configuration**: `inst/extdata/config.R` defines a global `CONFIG`
environment with:

- Table column widths and structures
- URL patterns for different platforms (GitHub, OSF, GitLab, Zenodo)
- Hyperlink templates
- Venue and codechecker display settings

### 3. Remote Configuration Retrieval (R/configuration.R)

**Main entry point**:
[`get_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/get_codecheck_yml.md)
fetches codecheck.yml from remote repositories.

**Multi-platform support** via
[`parse_repository_spec()`](http://codecheck.org.uk/codecheck/reference/parse_repository_spec.md):

- `github::org/repo` - GitHub repositories
- `osf::ABC12` - OSF projects (5-character IDs)
- `gitlab::project/repo` - GitLab.com projects
- `zenodo::1234567` - Zenodo records (7+ digit IDs)
- `zenodo-sandbox::1234567` - Zenodo Sandbox

Each platform has dedicated retrieval functions
([`get_codecheck_yml_github()`](http://codecheck.org.uk/codecheck/reference/get_codecheck_yml_github.md),
etc.) and results are cached using
[`R.cache::addMemoization()`](https://rdrr.io/pkg/R.cache/man/addMemoization.html).

## Key Data Structures

### codecheck.yml Structure

The YAML configuration file must contain:

- `certificate` - Pattern: NNNN-NNN (e.g., “2024-001”)
- `paper` - Title, authors (with name and optional ORCID), reference URL
- `codechecker` - Name and optional ORCID of checker(s)
- `manifest` - List of output files, each with `file` and `comment`
- `report` - DOI for the Zenodo certificate
- `repository` - URL(s) to the code repository
- `check_time` - ISO 8601 timestamp

See template at `inst/extdata/templates/codecheck.yml`.

### Register CSV Format

The register CSV contains columns:

- Certificate - ID (e.g., “2024-001”)
- Repository - Platform-prefixed spec (e.g.,
  “github::codecheckers/repo”)
- Type - Venue category (journal, conference, community, institution)
- Venue - Short venue name
- Issue - GitHub issue number for the CODECHECK
- Report - Zenodo DOI
- Check date - ISO 8601 date

## Templates

Templates use Pandoc and Markdown for rendering and the `whisker`
package for rendering specific parts of HTMLs using Mustache’s logicless
templating. Templates are located in `inst/extdata/templates/`:

- `cert/` - Certificate markdown and HTML templates
- `reg_tables/` - Register table templates
- `non_reg_tables/` - Venue/codechecker list templates
- `general/` - Shared HTML headers/footers

## Important Notes

- **GitHub API token**: Set `GITHUB_PAT` environment variable to avoid
  rate limits when rendering the register
- **Caching**: Remote configurations are cached via `R.cache`. Use
  [`register_clear_cache()`](http://codecheck.org.uk/codecheck/reference/register_clear_cache.md)
  to reset
- **ORCID format**: Must be without URL prefix (NNNN-NNNN-NNNN-NNNX
  format)
- **DOI validation**: Uses
  [`rorcid::check_dois()`](https://rdrr.io/pkg/rorcid/man/check_dois.html)
  and requires network access
- **UTF-8 encoding**: All YAML files should be UTF-8 encoded
- **Date formats**: Use ISO 8601 for all date/time fields
- **Manifest files**: Paths in the manifest are relative to the root of
  the repository
- **Zenodo sandbox**: Use `zenodo-sandbox::` prefix for testing uploads
  without affecting the main Zenodo repository
- **Configuration updates**: Update `inst/extdata/config.R` for changes
  in URL patterns, table structures, etc.
- **Testing**: Use `tinytest` for unit tests located in
  `inst/tinytest/`. Run tests with `tinytest::test_package("codecheck")`
  from the installed package or `tinytest::test_all(".")` from source.
- **Documentation**: Use `roxygen2` for function documentation
- **Changelog**: Always update `NEWS.md` when making changes. Each
  version should have its own section documenting new features, bug
  fixes, and breaking changes.

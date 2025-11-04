# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The `codecheck` package is an R package that assists in conducting [CODECHECKs](https://codecheck.org.uk/) - independent verification of computational research. It provides two main functions:

1. **Workspace creation tools** - Help researchers prepare CODECHECK workspaces with proper metadata and structure
2. **Register management tools** - Render and maintain the [CODECHECK Register](https://codecheck.org.uk/register/) which tracks all completed codechecks

## Installation & Development

Install the package:
```r
remotes::install_github("codecheckers/codecheck")
```

Run tests using `tinytest`:
```r
# Interactive testing
tinytest::test_all("/path/to/package")

# Or build, install, and test in a fresh environment
tinytest::build_install_test(".")
```

The package uses GitHub Actions for CI/CD. Check `.github/workflows/R-CMD-check.yaml` for the automated testing setup.

### Changelog Management

**IMPORTANT**: When making changes to the package, always update `NEWS.md` with:
- A brief description of the change
- For new features, document the user-facing functionality
- For bug fixes, reference the issue or describe the problem solved
- For breaking changes, clearly mark them as such

When bumping the version in `DESCRIPTION`, add a new section to `NEWS.md` with the version number and date. Follow the existing format with `# codecheck X.Y.Z` headers.

## Core Architecture

### 1. Workspace Creation (R/codecheck.R)

**Main entry point**: `create_codecheck_files()` creates the initial CODECHECK workspace including:

- A `codecheck.yml` file with required metadata (certificate ID, authors, manifest, etc.)
- A `codecheck/` directory with report templates

**Key functions**:

- `codecheck_metadata()` - Load and parse `codecheck.yml`
- `copy_manifest_files()` - Copy output files specified in the manifest to the codecheck folder
- `validate_codecheck_yml()` - Validate that a codecheck.yml file meets the specification (R/configuration.R:196)
- `complete_codecheck_yml()` - Analyze and complete codecheck.yml with missing fields; validates against specification; can add placeholders for mandatory and optional fields

**Lifecycle Journal automation**: Functions for auto-populating metadata from Lifecycle Journal articles:

- `get_lifecycle_metadata()` - Retrieve article metadata from CrossRef API using submission ID or DOI (prefix: `10.71240/lcyc.`)
- `update_codecheck_yml_from_lifecycle()` - Update local `codecheck.yml` with metadata; shows diff before applying changes; supports preview mode and selective field updates

**Zenodo integration**: Functions for uploading certificates to Zenodo:

- `get_or_create_zenodo_record()` - Create or retrieve a Zenodo record
- `upload_zenodo_metadata()` - Upload metadata from codecheck.yml
- `set_zenodo_certificate()` - Upload the PDF certificate

### 2. Register Management (R/register.R)

**Main entry point**: `register_render()` processes a CSV register file and generates multiple views:

- HTML pages for each certificate
- Markdown summaries
- JSON data files
- Filtered views by venue, codechecker, etc.

**Architecture flow**:

1. Load register CSV and config files (inst/extdata/config.R contains global CONFIG)
2. `preprocess_register()` enriches entries with remote codecheck.yml data (R/utils_preprocess_register.R)
3. Generate outputs:
   - `render_cert_htmls()` - HTML certificate pages (R/utils_render_cert_htmls.R)
   - `create_filtered_reg_csvs()` - CSV files filtered by venue/codechecker (R/utils_create_filtered_register_csvs.R)
   - `create_register_files()` - Main register tables (R/utils_render_register_mds.R, R/utils_render_register_htmls.R, R/utils_render_register_json.R)
   - `create_non_register_files()` - Lists of venues/codecheckers (R/utils_render_table_*.R)

**Configuration**: `inst/extdata/config.R` defines a global `CONFIG` environment with:

- Table column widths and structures
- URL patterns for different platforms (GitHub, OSF, GitLab, Zenodo)
- Hyperlink templates
- Venue and codechecker display settings

### 3. Remote Configuration Retrieval (R/configuration.R)

**Main entry point**: `get_codecheck_yml()` fetches codecheck.yml from remote repositories.

**Multi-platform support** via `parse_repository_spec()`:

- `github::org/repo` - GitHub repositories
- `osf::ABC12` - OSF projects (5-character IDs)
- `gitlab::project/repo` - GitLab.com projects
- `zenodo::1234567` - Zenodo records (7+ digit IDs)
- `zenodo-sandbox::1234567` - Zenodo Sandbox

Each platform has dedicated retrieval functions (`get_codecheck_yml_github()`, etc.) and results are cached using `R.cache::addMemoization()`.

## Key Data Structures

### codecheck.yml Structure

The YAML configuration file must contain:

- `certificate` - Pattern: NNNN-NNN (e.g., "2024-001")
- `paper` - Title, authors (with name and optional ORCID), reference URL
- `codechecker` - Name and optional ORCID of checker(s)
- `manifest` - List of output files, each with `file` and `comment`
- `report` - DOI for the Zenodo certificate
- `repository` - URL(s) to the code repository
- `check_time` - ISO 8601 timestamp

See template at `inst/extdata/templates/codecheck.yml`.

### Register CSV Format

The register CSV contains columns:

- Certificate - ID (e.g., "2024-001")
- Repository - Platform-prefixed spec (e.g., "github::codecheckers/repo")
- Type - Venue category (journal, conference, community, institution)
- Venue - Short venue name
- Issue - GitHub issue number for the CODECHECK
- Report - Zenodo DOI
- Check date - ISO 8601 date

## Templates

Templates use Pandoc and Markdown for rendering and the `whisker` package for rendering specific parts of HTMLs using Mustache's logicless templating.
Templates are located in `inst/extdata/templates/`:

- `cert/` - Certificate markdown and HTML templates
- `reg_tables/` - Register table templates
- `non_reg_tables/` - Venue/codechecker list templates
- `general/` - Shared HTML headers/footers

## Important Notes

- **GitHub API token**: Set `GITHUB_PAT` environment variable to avoid rate limits when rendering the register
- **Caching**: Remote configurations are cached via `R.cache`. Use `register_clear_cache()` to reset
- **ORCID format**: Must be without URL prefix (NNNN-NNNN-NNNN-NNNX format)
- **DOI validation**: Uses `rorcid::check_dois()` and requires network access
- **UTF-8 encoding**: All YAML files should be UTF-8 encoded
- **Date formats**: Use ISO 8601 for all date/time fields
- **Manifest files**: Paths in the manifest are relative to the root of the repository
- **Zenodo sandbox**: Use `zenodo-sandbox::` prefix for testing uploads without affecting the main Zenodo repository
- **Configuration updates**: Update `inst/extdata/config.R` for changes in URL patterns, table structures, etc.
- **Testing**: Use `tinytest` for unit tests located in `inst/tinytest/`. Run tests with `tinytest::test_package("codecheck")` from the installed package or `tinytest::test_all(".")` from source.
- **Documentation**: Use `roxygen2` for function documentation
- **Changelog**: Always update `NEWS.md` when making changes. Each version should have its own section documenting new features, bug fixes, and breaking changes.

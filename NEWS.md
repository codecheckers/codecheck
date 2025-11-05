# codecheck 0.22.0

## Certificate Automation and Validation

* **New feature**: Automatic certificate ID retrieval from GitHub issues
  - `get_certificate_from_github_issue()`: Searches codecheckers/register issues by author names
  - `is_placeholder_certificate()`: Detects placeholder certificate IDs and report DOIs
  - `update_certificate_from_github()`: Auto-updates certificate IDs from matching GitHub issues
  - `validate_certificate_for_rendering()`: Displays visual warnings in PDF for placeholder values
  - Certificate template now automatically attempts to retrieve certificate IDs during rendering
* **New feature**: YAML validation and field completion
  - `validate_yaml_syntax()`: Validates YAML syntax before parsing
  - `complete_codecheck_yml()`: Analyzes and adds missing mandatory/optional fields
  - Both functions integrated into certificate template
* **New feature**: External metadata validation via CrossRef and ORCID APIs
  - `validate_codecheck_yml_crossref()`: Validates paper metadata against CrossRef
  - `validate_codecheck_yml_orcid()`: Validates author/codechecker names against ORCID records
  - `validate_contents_references()`: Unified wrapper combining both validations
  - Integrated into certificate template with strict mode to fail rendering on mismatches

## Lifecycle Journal Integration

* **New feature**: Automatic metadata population from Lifecycle Journal (addresses #82)
  - `get_lifecycle_metadata()`: Retrieves article metadata via CrossRef API
  - `update_codecheck_yml_from_lifecycle()`: Auto-populates codecheck.yml with paper metadata
  - Smart field updates with preview mode and diff view before applying changes

## Bug Fixes

* **Critical fix**: Fixed `set_zenodo_certificate()` to use correct zen4R API signatures
  - `deleteFile()` now uses `deleteFile(recordId, filename)` instead of `deleteFile(fileId, recordId)`
  - `uploadFile()` now uses `uploadFile(path, record)` with record object instead of record ID
  - Fixes "cannot coerce type 'environment' to vector of type 'character'" error
* Fixed ORCID icon hyperlinks in PDF certificates using academicons package
  - Replaced complex tikz/svg implementation with simple `\aiOrcid` from academicons
  - Moved `\usepackage{hyperref}` to load after other packages to avoid conflicts
  - ORCID icons are now clickable links that work reliably across PDF viewers
* Fixed `latex_summary_of_metadata()` and `latex_summary_of_manifest()` to handle NULL/empty fields
* Fixed `get_or_create_zenodo_record()` to call correct function (`get_zenodo_id()`)
* **Critical fix**: Fixed `upload_zenodo_metadata()` to properly set alternate identifiers per Zenodo curation policy
  - Certificate ID now correctly added as **alternate identifiers** (not related identifiers)
  - Two alternate identifier entries as required by policy:
    - URL schema: `http://cdchck.science/register/certs/<CERT ID>`
    - Other schema: `cdchck.science/register/certs/<CERT ID>` (without protocol)
  - Sets `metadata$alternate_identifiers` directly with proper structure
  - Related identifiers now only include paper (reviews) and repository (isSupplementedBy)
  - Paper DOI uses scheme="doi" and relation_type="reviews"
  - Repository URL uses scheme="url" and relation_type="issupplementedby"
* **Code quality**: Refactored DOI placeholder detection to eliminate code duplication
  - Created internal `is_doi_placeholder()` helper function
  - Now used by both `is_placeholder_certificate()` and `get_or_create_zenodo_record()`
  - Centralized placeholder detection logic for easier maintenance

## Enhancements

* **Refactored Zenodo certificate upload**: `set_zenodo_certificate()` renamed to `upload_zenodo_certificate()`
  - **New feature**: Can now upload additional files alongside the certificate via `additional_files` parameter
  - Certificate is always uploaded first to ensure it becomes the preview file for the Zenodo record
  - `set_zenodo_certificate()` retained as an alias for backward compatibility
  - Returns list with certificate result and additional_files results
* **Smart certificate upload**: `upload_zenodo_certificate()` checks for existing certificate files before uploading
  - Automatically detects existing PDF files on Zenodo record
  - Prompts user whether to delete existing files and upload new one, or abort operation
  - New warn parameter (default TRUE) for interactive prompting; set FALSE for automated/non-interactive contexts
  - Shows file details (name, size) before deletion
  - Handles multiple PDF files and provides clear feedback during deletion/upload
  - Comprehensive error handling with graceful degradation
  - New test suite with 27 tests covering all scenarios
* **Automatic YAML updating**: `get_or_create_zenodo_record()` now automatically updates codecheck.yml with Zenodo DOI
  - When creating a new Zenodo record, automatically updates the report field in codecheck.yml
  - Detects empty or placeholder values (FIXME, TODO, placeholder, XXXXX, etc.) and updates automatically
  - For non-placeholder values, asks user confirmation before overwriting (when warn=TRUE)
  - Handles NULL report field gracefully
  - Preserves all other fields in codecheck.yml during update
  - New yml_file parameter allows specifying alternate YAML file location
  - Comprehensive test suite with 31 tests using mocked Zenodo API
* **Zenodo curation policy compliance**: `upload_zenodo_metadata()` now fully complies with CODECHECK Zenodo community curation policy
  - Publisher set to "CODECHECK Community on Zenodo" (was "CODECHECK")
  - Resource type set to "publication-report" (was "publication-preprint")
  - Description includes certificate summary as required by policy
  - Adds related identifier for original paper with "reviews" relation (scheme="doi", relation_type="reviews", resource_type="publication-article")
  - Adds related identifier for code repository with "isSupplementedBy" relation (scheme="url", relation_type="issupplementedby", resource_type=auto-detected)
  - Adds **two alternate identifiers** for certificate ID (URL and Other schemas) - correctly uses alternate_identifiers field per curation policy
  - **Smart repository type detection**: Automatically detects if repository is software (GitHub, GitLab, Codeberg, etc.) or dataset (DataCite DOI)
  - **Configurable resource types**: New `resource_types` parameter allows overriding defaults via named list (paper, repository)
  - Prints confidence level messages for low/medium confidence detections to allow user verification
  - Validates required fields (certificate ID, warns for missing summary)
  - Handles NULL/empty repository gracefully
  - Extracts clean DOI from doi.org URLs
  - Comprehensive test suite with 38 tests including auto-detection and override scenarios
* Zenodo functions now load metadata from codecheck.yml by default
* DOI validation is now platform-agnostic (Zenodo, OSF, ResearchEquals, etc.)
* Removed pifont package dependency; now uses UTF-8 emoji ⚠ for warnings
* Enhanced error messages with clearer guidance
* Added ~230 new tests across all features
  
# codecheck 0.21.0

* Added pkgdown configuration and workflow for documentation site
* Added CLAUDE.md with comprehensive guidance for AI-assisted development
* Fixed typo in `get_abstract_text_crossref()` (`referenc` → `reference`)
* Fixed test file error handling for missing config files
* Fixed variable scoping issues in tinytest suite
* Added launch pad link to documentation
* Added clarifying comments in core functions
* **Bug fix**: Fixed `validate_codecheck_yml()` repository URL validation - now correctly calls `http_error()` on response objects instead of URL strings

# codecheck 0.20.0

* Renamed fields in register output for consistency
* Updated footer with improved contact information
* Removed individual maintainer references from footer

# codecheck 0.19.0

* Fixed namespace issues
* Added support for specifying from-to range when rendering register

# codecheck 0.18.0

* Added validation of certificate identifier format in `validate_codecheck_yml()`
* Ensures certificate IDs follow the NNNN-NNN pattern (e.g., "2024-001")

# codecheck 0.17.0

* Added support for certificate download from ResearchEquals platform
* Extended `get_cert_link()` to handle ResearchEquals DOIs

# codecheck 0.16.0

* Added support for sub-paths within GitHub repositories to access codecheck.yml
* Enables accessing codecheck.yml files in subdirectories using `github::org/repo|subpath` syntax
* Updated check template
* Added TL;DR section to README for template usage

# codecheck 0.15.0

* Added handling for PDF import in template certificate
* Improved certificate template generation

# codecheck 0.14.0

* Added TU Delft Data Champion Centre (DCC) as venue
* Added eLife journal as venue
* Removed unused venue entries
* Fixed Zenodo hyperlinks in register output
* Hardened code for missing ORCIDs in codechecker field
* Added venue hyperlinks to register pages
* Fixed issue with missing codechecks column
* Reordered fields in the UI for better usability

# codecheck 0.12.0

* Added support for retrieving codecheck.yml files from Zenodo records
* New repository specification: `zenodo::1234567` and `zenodo-sandbox::1234567`
* Fixed various warnings and notes from R CMD check

# codecheck 0.11.6

* Fixed JSON output to not include markdown hyperlinks
* Added tests for rendering functions

# codecheck 0.11.5

* Fixed imports to reflect API changes in zen4R package
* Added templates for the codecheck report

# codecheck 0.11.4

* Replaced custom `url_exists()` with `httr::http_error()`
* Improved URL validation

# codecheck 0.11.3

* Added missing import in DESCRIPTION
* Added logging of cache usage for check and render operations

# codecheck 0.11.2

* Fixed codechecker hyperlink generation when ORCID ID is missing

# codecheck 0.11.1

* Fixed certificate pages that have no certificate preview available

# codecheck 0.11.0

* Added generation of individual certificate HTML pages
* New function `create_cert_md()` for certificate markdown generation
* Added abstract retrieval from CrossRef and OpenAlex APIs

# codecheck 0.10.1

* Fixed venue type page hyperlinks

# codecheck 0.10.0

* Fixed URL links in venues and venue type tables
* Made non-register venue tables use plural naming
* Improved hyperlink consistency across all outputs

# codecheck 0.9.0 / 0.8.0

* Replaced repository column in register with platform-prefixed specifications
* Added support for multiple repository platforms (GitHub, OSF, GitLab, Zenodo)

# codecheck 0.7.0

* Added Amsterdam UMC as venue
* Added codecheckers extra text section
* Improved venue management

# codecheck 0.6.0

* Split register by type (journal, conference, community, institution)
* Created filtered CSV files by venue and codechecker
* Refactored register rendering architecture
* Updated column width configurations
* Moved hyperlinks configuration to config.R

# codecheck 0.5.0

* Initial support for multiple output formats (HTML, JSON, Markdown)
* Added JSON register output
* Improved register table rendering

# codecheck 0.4.0

* Enhanced register filtering capabilities
* Added codechecker-specific register views

# codecheck 0.3.0

* Improved register preprocessing
* Added remote configuration retrieval

# codecheck 0.2.0

* Added register rendering functionality
* Support for multiple venues and codecheckers

# codecheck 0.1.0

* Initial release
* Basic CODECHECK workspace creation
* Certificate generation support
* Integration with Zenodo for certificate uploads

# codecheck 0.0.0.90xx

* Added tests using `tinytest`
* Added a `NEWS.md` file to track changes to the package

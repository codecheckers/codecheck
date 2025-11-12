# Changelog

## codecheck (development version)

### GitHub Issue Validation

- **New validation function**: Added
  [`validate_certificate_github_issue()`](http://codecheck.org.uk/codecheck/reference/validate_certificate_github_issue.md)
  to verify that certificate identifiers exist in the
  codecheckers/register GitHub repository
- **Issue state checking**: Warns if the certificate’s GitHub issue is
  closed (indicating the CODECHECK is already complete and published)
- **Assignment validation**: Warns if the certificate’s GitHub issue is
  unassigned (no codechecker assigned yet)
- **Strict mode**: Optional strict mode (`strict = TRUE`) treats
  warnings as errors, stopping certificate processing if issues are
  found
- **Placeholder handling**: Automatically skips validation for
  placeholder certificate identifiers
- **Comprehensive error handling**: Provides clear error messages for
  missing issues, API rate limits, and authentication problems
- **GitHub Actions integration**: Updated R-CMD-check workflow to
  include GITHUB_PAT token for API access during testing

### ORCID Validation Improvements

- **Graceful authentication handling**: ORCID validation functions now
  handle authentication failures gracefully with clear error messages
  instead of requiring interactive login
- **New `skip_on_auth_error` parameter**: Added to
  [`validate_codecheck_yml_orcid()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml_orcid.md)
  and
  [`validate_contents_references()`](http://codecheck.org.uk/codecheck/reference/validate_contents_references.md)
  to control behavior when ORCID authentication is unavailable. By
  default (`FALSE`), functions require authentication. Set to `TRUE` to
  skip validation when authentication is not available (useful for CI/CD
  pipelines and test environments).
- **Enhanced error messages**: Clear guidance provided when ORCID
  authentication is needed, with instructions for setting `ORCID_TOKEN`
  environment variable or running
  [`rorcid::orcid_auth()`](https://rdrr.io/pkg/rorcid/man/orcid_auth.html)
- **Opt-in skipping**: Certificate authors can choose to skip ORCID
  validation by setting `skip_on_auth_error = TRUE` in the certificate
  template
- **Better feedback**: Functions now return a `skipped` field indicating
  whether validation was skipped due to authentication issues

### Manifest Rendering Enhancements

- **Expanded format support**: Certificates can now render additional
  file formats in the manifest section:
  - Image formats: TIF, TIFF, GIF, EPS, and SVG (with automatic
    conversion)
  - Data formats: JSON (with pretty-printing and configurable line
    limits) and TSV (tab-separated values)
  - Multi-page PDFs are now fully supported with automatic page
    detection
- **GIF format support**: GIF images are now automatically converted to
  PNG during certificate rendering. pdflatex does not natively support
  GIF format, so conversion is required.
- **TIF/TIFF format support**: TIF and TIFF images are now automatically
  converted to PNG during certificate rendering.
- **New dependency**: Added `magick` package as a required dependency
  for image format conversion (TIF/TIFF/GIF to PNG). Previously this was
  optional, but is now mandatory for proper image format support.
- **Graceful error handling**: Missing, corrupted, or unsupported
  manifest files no longer fail the entire certificate rendering:
  - [`copy_manifest_files()`](http://codecheck.org.uk/codecheck/reference/copy_manifest_files.md)
    now warns about missing files instead of stopping execution,
    allowing the certificate to render with available files
  - Each problematic file displays a formatted error message in the PDF
    output, helping codecheckers identify and fix issues
  - File-level error handling prevents individual file failures from
    blocking the entire certificate generation
  - Error messages include the filename and specific error reason for
    easier debugging

### Git Integration

- **New function**: Added
  [`get_git_info()`](http://codecheck.org.uk/codecheck/reference/get_git_info.md)
  to retrieve git commit information from a repository path
- **Proper dependency handling**: git2r dependency is now properly
  handled through the package function rather than inline template code
- **Template simplification**: Certificate templates now use
  [`get_git_info()`](http://codecheck.org.uk/codecheck/reference/get_git_info.md)
  instead of inline git2r calls, improving maintainability and error
  handling
- **File existence checks**: All manifest rendering functions now check
  for file existence before processing and display helpful error
  messages.
- **Improved error messages**: Error messages are now displayed as
  formatted LaTeX boxes in the rendered PDF with specific information
  about what went wrong (e.g., “File not found”, “Failed to convert GIF
  image”, “Unsupported file format (.xyz)”).
- **Improved maintainability**: Manifest rendering code refactored into
  modular, testable components
- **Comprehensive testing**: Added extensive test suite covering all
  supported formats including GIF with test fixtures

## codecheck 0.22.0

### Certificate Automation and Validation

- **Automatic certificate ID retrieval**: Certificate IDs can now be
  automatically retrieved from GitHub issues by searching the
  codecheckers/register repository by author names. The certificate
  template attempts this automatically during rendering.
- **YAML validation and field completion**: The codecheck.yml file can
  now be validated for syntax errors and automatically completed with
  missing mandatory/optional fields.
- **External metadata validation**: Paper metadata can be validated
  against CrossRef, and author/codechecker names can be validated
  against ORCID records. Strict mode fails rendering on mismatches.
- **Placeholder detection**: Placeholder certificate IDs and report DOIs
  are automatically detected and display visual warnings in rendered
  PDFs.

### Lifecycle Journal Integration

- **Automatic metadata population**: Article metadata from Lifecycle
  Journal can be automatically retrieved and used to populate
  codecheck.yml fields (addresses
  [\#82](https://github.com/codecheckers/codecheck/issues/82)). Smart
  field updates with preview mode and diff view before applying changes.

### Bug Fixes

- **Critical fix**: Fixed Zenodo certificate upload to use correct zen4R
  API signatures (fixes “cannot coerce type ‘environment’ to vector of
  type ‘character’” error)
- Fixed ORCID icon hyperlinks in PDF certificates - icons are now
  clickable links that work reliably across PDF viewers
- Fixed handling of NULL/empty fields in certificate rendering
- **Critical fix**: Fixed Zenodo metadata upload to properly set
  alternate identifiers per Zenodo curation policy (certificate ID now
  correctly added as alternate identifiers with proper URL and Other
  schemas)
- Fixed R CMD check warnings related to variable bindings
- Reorganized package structure into focused files for better
  maintainability

### Enhancements

- **Enhanced Zenodo certificate upload**: Can now upload additional
  files alongside the certificate, including automatic upload of
  certificate source files (.Rmd or .qmd). Smart detection of existing
  files with user prompts before replacement. Backward compatible via
  alias.
- **Automatic YAML updating**: When creating new Zenodo records, the
  codecheck.yml file is automatically updated with the Zenodo DOI.
  Detects and replaces placeholder values, asks for confirmation on
  non-placeholder updates.
- **Automatic CODECHECK community submission**: Newly created Zenodo
  records are automatically submitted to the CODECHECK community
  (<https://zenodo.org/communities/codecheck/>) ensuring
  discoverability.
- **Zenodo curation policy compliance**: Metadata uploads now fully
  comply with CODECHECK Zenodo community curation policy (correct
  publisher, resource type, alternate identifiers, and related
  identifiers with automatic repository type detection).
- Zenodo functions now load metadata from codecheck.yml by default
- DOI validation is now platform-agnostic (Zenodo, OSF, ResearchEquals,
  etc.)
- Enhanced error messages with clearer guidance
- Added ~230 new tests across all features

## codecheck 0.21.0

- Added pkgdown configuration and workflow for documentation site
- Added CLAUDE.md with comprehensive guidance for AI-assisted
  development
- Fixed typo in abstract text retrieval
- Fixed test file error handling for missing config files
- Fixed variable scoping issues in test suite
- Added launch pad link to documentation
- Added clarifying comments in core functions
- **Bug fix**: Fixed repository URL validation to properly check HTTP
  responses

## codecheck 0.20.0

- Renamed fields in register output for consistency
- Updated footer with improved contact information
- Removed individual maintainer references from footer

## codecheck 0.19.0

- Fixed namespace issues
- Added support for specifying from-to range when rendering register

## codecheck 0.18.0

- Added validation of certificate identifier format in
  [`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md)
- Ensures certificate IDs follow the NNNN-NNN pattern (e.g., “2024-001”)

## codecheck 0.17.0

- Added support for certificate download from ResearchEquals platform
- Extended
  [`get_cert_link()`](http://codecheck.org.uk/codecheck/reference/get_cert_link.md)
  to handle ResearchEquals DOIs

## codecheck 0.16.0

- Added support for sub-paths within GitHub repositories to access
  codecheck.yml
- Enables accessing codecheck.yml files in subdirectories using
  `github::org/repo|subpath` syntax
- Updated check template
- Added TL;DR section to README for template usage

## codecheck 0.15.0

- Added handling for PDF import in template certificate
- Improved certificate template generation

## codecheck 0.14.0

- Added TU Delft Data Champion Centre (DCC) as venue
- Added eLife journal as venue
- Removed unused venue entries
- Fixed Zenodo hyperlinks in register output
- Hardened code for missing ORCIDs in codechecker field
- Added venue hyperlinks to register pages
- Fixed issue with missing codechecks column
- Reordered fields in the UI for better usability

## codecheck 0.12.0

- Added support for retrieving codecheck.yml files from Zenodo records
- New repository specification: `zenodo::1234567` and
  `zenodo-sandbox::1234567`
- Fixed various warnings and notes from R CMD check

## codecheck 0.11.6

- Fixed JSON output to not include markdown hyperlinks
- Added tests for rendering functions

## codecheck 0.11.5

- Fixed imports to reflect API changes in zen4R package
- Added templates for the codecheck report

## codecheck 0.11.4

- Replaced custom `url_exists()` with
  [`httr::http_error()`](https://httr.r-lib.org/reference/http_error.html)
- Improved URL validation

## codecheck 0.11.3

- Added missing import in DESCRIPTION
- Added logging of cache usage for check and render operations

## codecheck 0.11.2

- Fixed codechecker hyperlink generation when ORCID ID is missing

## codecheck 0.11.1

- Fixed certificate pages that have no certificate preview available

## codecheck 0.11.0

- Added generation of individual certificate HTML pages
- New function
  [`create_cert_md()`](http://codecheck.org.uk/codecheck/reference/create_cert_md.md)
  for certificate markdown generation
- Added abstract retrieval from CrossRef and OpenAlex APIs

## codecheck 0.10.1

- Fixed venue type page hyperlinks

## codecheck 0.10.0

- Fixed URL links in venues and venue type tables
- Made non-register venue tables use plural naming
- Improved hyperlink consistency across all outputs

## codecheck 0.9.0 / 0.8.0

- Replaced repository column in register with platform-prefixed
  specifications
- Added support for multiple repository platforms (GitHub, OSF, GitLab,
  Zenodo)

## codecheck 0.7.0

- Added Amsterdam UMC as venue
- Added codecheckers extra text section
- Improved venue management

## codecheck 0.6.0

- Split register by type (journal, conference, community, institution)
- Created filtered CSV files by venue and codechecker
- Refactored register rendering architecture
- Updated column width configurations
- Moved hyperlinks configuration to config.R

## codecheck 0.5.0

- Initial support for multiple output formats (HTML, JSON, Markdown)
- Added JSON register output
- Improved register table rendering

## codecheck 0.4.0

- Enhanced register filtering capabilities
- Added codechecker-specific register views

## codecheck 0.3.0

- Improved register preprocessing
- Added remote configuration retrieval

## codecheck 0.2.0

- Added register rendering functionality
- Support for multiple venues and codecheckers

## codecheck 0.1.0

- Initial release
- Basic CODECHECK workspace creation
- Certificate generation support
- Integration with Zenodo for certificate uploads

## codecheck 0.0.0.90xx

- Added tests using `tinytest`
- Added a `NEWS.md` file to track changes to the package

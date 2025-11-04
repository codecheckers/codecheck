# codecheck 0.22.0

* **New feature**: `validate_yaml_syntax()` - Validate YAML syntax before parsing
  - Checks if a YAML file has valid syntax that can be parsed
  - Provides clear error messages for syntax errors
  - Integrated into certificate template (codecheck.Rmd) to prevent compilation with invalid YAML
  - Can be used standalone with `stop_on_error = FALSE` to check validity without stopping execution
  - Comprehensive test suite in `test_yaml_syntax_validation.R` (6 tests)
* **New feature**: `complete_codecheck_yml()` - Analyze and complete codecheck.yml files with missing fields
  - Validates codecheck.yml against the specification at https://codecheck.org.uk/spec/config/1.0/
  - Reports missing mandatory, recommended, and optional fields
  - Can add placeholders for missing mandatory fields (`add_mandatory = TRUE`)
  - Can add placeholders for all missing fields including recommended and optional (`add_optional = TRUE`)
  - Shows diff of changes before applying (similar to `update_codecheck_yml_from_lifecycle()`)
  - Comprehensive test suite in `test_complete_codecheck_yml.R`
* **New feature**: `validate_codecheck_yml_crossref()` - Validate metadata against CrossRef
  - Retrieves paper metadata from CrossRef API using the paper's DOI
  - Validates title matches between local codecheck.yml and published paper
  - Validates author information (names and ORCIDs) against CrossRef data
  - Validates codechecker information is present and properly formatted
  - Supports strict mode that throws errors on mismatches (fails certificate rendering)
  - Integrated into certificate template (codecheck.Rmd) for automatic validation during rendering
  - Comprehensive test suite in `test_crossref_validation.R` (13 tests)
* **New feature**: Lifecycle Journal automation (addresses #82)
  - `get_lifecycle_metadata()`: Retrieve article metadata from Lifecycle Journal via CrossRef API using submission ID or DOI
  - `update_codecheck_yml_from_lifecycle()`: Auto-populate `codecheck.yml` with paper metadata (title, authors with ORCIDs, DOI reference)
  - Preview changes before applying with diff view
  - Smart field updates: only populate empty/placeholder fields by default, with option to overwrite existing fields
  - `test_lifecycle_journal.R`: 24 tests validating metadata retrieval and codecheck.yml updates
* **New tests**: Added comprehensive test coverage (~180 new tests)
  
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

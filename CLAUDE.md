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

## Design Principles

### Separation of Concerns: Data vs. Presentation

**CRITICAL PRINCIPLE**: R functions should focus on data preparation and
logic, NOT HTML generation.

**✅ DO**: - Prepare data in R functions (e.g., extract metadata, create
data structures) - Store HTML structure in template files (`.html`,
`.md` with Mustache/Whisker placeholders) - Use R to populate template
placeholders with data values - Return data objects (lists, data frames,
strings) from R functions

**❌ DON’T**: - Generate HTML tags directly in R functions (e.g.,
`sprintf('<a href="%s">...</a>')`) - Build complex HTML structures using
string concatenation in R - Mix presentation logic with data processing
logic

**Example of correct approach**:

``` r
# R function - prepares data only
generate_profile_data <- function(orcid) {
  profile <- get_profile(orcid)
  return(list(
    has_orcid = !is.null(profile$orcid),
    orcid = profile$orcid,
    has_github = !is.null(profile$github_handle),
    github_handle = profile$github_handle
  ))
}

# Template file (profile.html) - contains HTML structure
# <a href="https://orcid.org/{{orcid}}">
#   <i class="ai ai-orcid"></i> {{orcid}}
# </a>

# Rendering function - combines data with template
render_profile <- function(orcid) {
  data <- generate_profile_data(orcid)
  template <- readLines("profile.html")
  whisker::render(template, data)
}
```

**Why this matters**: - **Maintainability**: HTML changes don’t require
R code changes - **Testability**: R functions can be tested without
parsing HTML - **Readability**: Templates are easier to understand than
R strings with escaped HTML - **Collaboration**: Designers can work on
templates without touching R code - **Consistency**: CSS classes and
HTML structure remain consistent across the codebase

**Current implementation**: - Template files in
`inst/extdata/templates/` contain HTML structure - R functions use
`whisker::render()` or
[`sprintf()`](https://rdrr.io/r/base/sprintf.html) to fill
placeholders - Functions like
[`generate_codechecker_profile_links()`](http://codecheck.org.uk/codecheck/reference/generate_codechecker_profile_links.md),
[`generate_footer_build_info()`](http://codecheck.org.uk/codecheck/reference/generate_footer_build_info.md),
and
[`generate_meta_generator_content()`](http://codecheck.org.uk/codecheck/reference/generate_meta_generator_content.md)
return content strings without HTML wrapper tags - HTML wrapper tags
(`<p>`, `<meta>`, etc.) are in template files

### Version Management

The package follows [Semantic Versioning](https://semver.org/)
(MAJOR.MINOR.PATCH): - **MAJOR** version: Incompatible API changes -
**MINOR** version: New functionality in a backwards-compatible manner -
**PATCH** version: Backwards-compatible bug fixes - **Development**
version: Append `.9000` to the version number (e.g., `0.23.0.9000`)

**Bumping versions using usethis** (recommended method):

``` r
# Bump patch version (0.23.0 -> 0.23.1)
usethis::use_version("patch")

# Bump minor version (0.23.0 -> 0.24.0)
usethis::use_version("minor")

# Bump major version (0.23.0 -> 1.0.0)
usethis::use_version("major")

# Start development version (0.23.0 -> 0.23.0.9000)
usethis::use_version("dev")
```

**Manual version bumping**:

If `usethis::use_version()` fails due to uncommitted changes or
interactive session requirements:

1.  Edit `DESCRIPTION` and update the `Version:` field
2.  Add a new section to `NEWS.md` with the version number and date
3.  Commit the changes with a message like “Bump version to X.Y.Z”

**Release procedure**:

1.  Ensure all changes are documented in `NEWS.md`
2.  Ensure all tests pass: `tinytest::build_install_test(".")`
3.  Bump version to release version (remove `.9000` suffix)
4.  Commit: `git commit -m "Release version X.Y.Z"`
5.  Tag the release: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
6.  Push with tags: `git push && git push --tags`
7.  Immediately bump to development version:
    `usethis::use_version("dev")`
8.  Commit: `git commit -m "Start development version X.Y.Z.9000"`

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
- [`validate_certificate_github_issue()`](http://codecheck.org.uk/codecheck/reference/validate_certificate_github_issue.md) -
  Validates certificate identifier exists in GitHub register issues;
  checks issue state (warns if closed) and assignment (warns if
  unassigned); stops with error if no matching issue found; supports
  strict mode where warnings become errors; automatically skips
  validation for placeholder certificates (R/validation.R:1204)

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

The register management system transforms a simple CSV file
(`register.csv`) into a rich, multi-format website at
<https://codecheck.org.uk/register/>. The system generates:

- **Individual certificate pages** - HTML pages with certificate
  details, abstracts, and embedded PDFs
- **Register tables** - Multiple views (HTML, Markdown, JSON, CSV) of
  all certificates
- **Filtered views** - Separate pages for each venue, venue type, and
  codechecker
- **Summary pages** - Lists of all venues and codecheckers with
  statistics

#### 2.1. Main Entry Points

**[`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)**
(R/register.R:26) - Main function that orchestrates the entire rendering
process: - Parameters: - `register`: Data frame from `register.csv`
(default: reads from file) - `filter_by`: Vector of filters to apply,
e.g., `c("venues", "codecheckers")` - `outputs`: Output formats to
generate, e.g., `c("html", "md", "json")` - `config`: Path(s) to config
file(s) to source - `from`, `to`: Range of register entries to process
(useful for incremental rendering)

**[`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)**
(R/register.R:78) - Validates all register entries: - Checks certificate
IDs match between register.csv and codecheck.yml - Verifies GitHub issue
status - Does NOT validate codecheck.yml files (use
[`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md)
for that)

**[`register_clear_cache()`](http://codecheck.org.uk/codecheck/reference/register_clear_cache.md)**
(R/utils_preprocess_register.R:8) - Clears the R.cache directory used
for storing remote codecheck.yml files

#### 2.2. Register Rendering Pipeline

The rendering process follows this sequence:

    1. Load register.csv and config.R
       └─> register_render()
           ├─> source(config.R)  # Loads CONFIG environment
           └─> subset register by from:to range

    2. Preprocess register (add metadata from remote codecheck.yml files)
       └─> preprocess_register()
           ├─> add_codechecker()       # Extract codechecker ORCIDs
           ├─> add_cert_links()        # Create certificate hyperlinks
           ├─> add_report_links()      # Extract Zenodo DOI from codecheck.yml
           ├─> add_issue_number_links()# Create GitHub issue links
           ├─> add_check_time()        # Extract check_time from codecheck.yml
           └─> add_paper_links()       # Extract paper title and reference

    3. Render individual certificate pages (if "html" in outputs)
       └─> render_cert_htmls()
           └─> For each certificate:
               ├─> download_cert_pdf()      # Download PDF from Zenodo
               ├─> convert_cert_pdf_to_png()# Convert PDF pages to PNG images
               ├─> create_cert_md()         # Create Markdown with metadata
               │   ├─> add_paper_details_md()   # Title, authors, abstract
               │   └─> add_codecheck_details_md()# Codechecker, dates, summary
               └─> render_cert_html()       # Render MD to HTML with Pandoc

    4. Create filtered CSV files
       └─> create_filtered_reg_csvs()
           └─> For each filter (venues, codecheckers):
               ├─> Group by filter column
               └─> Write CSV for each group

    5. Create register tables (original + filtered)
       └─> create_register_files()
           ├─> create_original_register_files()  # Main register
           └─> For each filter:
               ├─> Group by filter column
               └─> For each group:
                   ├─> render_register_md()  # Markdown table
                   ├─> render_html()         # HTML from markdown
                   └─> render_register_json()# JSON + featured.json + stats.json

    6. Create non-register summary pages
       └─> create_non_register_files()
           └─> For each filter:
               ├─> create_venues_tables()       # All venues + by type
               │   ├─> create_all_venues_table()
               │   └─> create_venue_type_tables()
               ├─> create_all_codecheckers_table()
               └─> For each table:
                   ├─> render_html()         # HTML page
                   └─> write JSON            # JSON file

#### 2.3. Key Utility Files

**R/utils_preprocess_register.R** - Data enrichment functions: -
[`add_paper_links()`](http://codecheck.org.uk/codecheck/reference/add_paper_links.md) -
Creates markdown links to papers using title and reference from
codecheck.yml -
[`add_report_links()`](http://codecheck.org.uk/codecheck/reference/add_report_links.md) -
Extracts Zenodo DOI from codecheck.yml -
[`add_issue_number_links()`](http://codecheck.org.uk/codecheck/reference/add_issue_number_links.md) -
Creates GitHub issue links -
[`add_check_time()`](http://codecheck.org.uk/codecheck/reference/add_check_time.md) -
Extracts and formats check_time using
[`parsedate::parse_date()`](https://rdrr.io/pkg/parsedate/man/parse_date.html) -
[`add_codechecker()`](http://codecheck.org.uk/codecheck/reference/add_codechecker.md) -
Extracts codechecker ORCIDs and builds ORCID→name dictionary in
`CONFIG$DICT_ORCID_ID_NAME` -
[`add_cert_links()`](http://codecheck.org.uk/codecheck/reference/add_cert_links.md) -
Creates certificate page links and adds Certificate ID/Link columns

**R/utils_render_cert_htmls.R** - Certificate page generation: -
[`render_cert_htmls()`](http://codecheck.org.uk/codecheck/reference/render_cert_htmls.md) -
Orchestrates certificate page creation for all entries -
[`download_cert_pdf()`](http://codecheck.org.uk/codecheck/reference/download_cert_pdf.md) -
Downloads certificate PDF from Zenodo (R/utils_download_certs.R) -
[`convert_cert_pdf_to_png()`](http://codecheck.org.uk/codecheck/reference/convert_cert_pdf_to_png.md) -
Converts PDF pages to PNG images using
[`pdftools::pdf_convert()`](https://docs.ropensci.org/pdftools//reference/pdf_render_page.html) -
[`create_cert_md()`](http://codecheck.org.uk/codecheck/reference/create_cert_md.md) -
Creates Markdown content from templates -
[`render_cert_html()`](http://codecheck.org.uk/codecheck/reference/render_cert_html.md) -
Renders HTML using Pandoc via
[`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html) -
[`edit_html_lib_paths()`](http://codecheck.org.uk/codecheck/reference/edit_html_lib_paths.md) -
Adjusts relative paths to shared `docs/libs/` folder to avoid
duplication

**R/utils_render_cert_md.R** - Certificate markdown creation: -
[`create_cert_md()`](http://codecheck.org.uk/codecheck/reference/create_cert_md.md) -
Main function for creating certificate markdown -
[`add_paper_details_md()`](http://codecheck.org.uk/codecheck/reference/add_paper_details_md.md) -
Adds paper title, authors (with ORCID links), reference -
[`add_codecheck_details_md()`](http://codecheck.org.uk/codecheck/reference/add_codecheck_details_md.md) -
Adds codechecker names, check time, summary, certificate ID -
[`add_abstract()`](http://codecheck.org.uk/codecheck/reference/add_abstract.md) -
Attempts to fetch abstract from CrossRef or OpenAlex -
[`get_abstract_text_crossref()`](http://codecheck.org.uk/codecheck/reference/get_abstract_text_crossref.md) -
Fetches abstract from CrossRef API -
[`get_abstract_text_openalex()`](http://codecheck.org.uk/codecheck/reference/get_abstract_text_openalex.md) -
Fetches abstract from OpenAlex API (handles inverted index format) -
[`add_repository_hyperlink()`](http://codecheck.org.uk/codecheck/reference/add_repository_hyperlink.md) -
Creates repository links based on platform (GitHub, OSF, GitLab, Zenodo)

**R/utils_create_filtered_register_csvs.R** - CSV generation: -
[`create_filtered_reg_csvs()`](http://codecheck.org.uk/codecheck/reference/create_filtered_reg_csvs.md) -
Creates CSV files for each venue/codechecker - For codecheckers: Reads
temporary CSV (register has lists in Codechecker column), unnests, then
groups - Uses `CONFIG$FILTER_COLUMN_NAMES` to determine grouping column

**R/utils_render_register_general.r** - Core register rendering: -
[`create_register_files()`](http://codecheck.org.uk/codecheck/reference/create_register_files.md) -
Orchestrates creation of all register views (original + filtered) -
[`create_original_register_files()`](http://codecheck.org.uk/codecheck/reference/create_original_register_files.md) -
Renders main register in all output formats -
[`render_register()`](http://codecheck.org.uk/codecheck/reference/render_register.md) -
Dispatches to format-specific renderer (MD, HTML, or JSON) -
[`generate_output_dir()`](http://codecheck.org.uk/codecheck/reference/generate_output_dir.md) -
Creates output directory path based on filter and subcategory -
[`generate_table_details()`](http://codecheck.org.uk/codecheck/reference/generate_table_details.md) -
Creates metadata dict with name, slug, subcat, output_dir -
[`filter_and_drop_register_columns()`](http://codecheck.org.uk/codecheck/reference/filter_and_drop_register_columns.md) -
Selects and orders columns per filter and format (uses hierarchical
`CONFIG$REGISTER_COLUMNS`) -
[`add_venue_hyperlinks_reg()`](http://codecheck.org.uk/codecheck/reference/add_venue_hyperlinks_reg.md) -
Adds markdown links to venue pages -
[`add_venue_type_hyperlinks_reg()`](http://codecheck.org.uk/codecheck/reference/add_venue_type_hyperlinks_reg.md) -
Adds markdown links to venue type pages

**R/utils_render_register_mds.R** - Markdown table generation: -
[`render_register_md()`](http://codecheck.org.uk/codecheck/reference/render_register_md.md) -
Creates markdown table with title and hyperlinks -
[`create_md_table()`](http://codecheck.org.uk/codecheck/reference/create_md_table.md) -
Uses [`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) to
create markdown table, adjusts column widths using
`CONFIG$MD_TABLE_COLUMN_WIDTHS` -
[`add_markdown_title()`](http://codecheck.org.uk/codecheck/reference/add_markdown_title.md) -
Adds title using functions from `CONFIG$MD_TITLES`

**R/utils_render_register_htmls.R** - HTML generation: -
[`render_html()`](http://codecheck.org.uk/codecheck/reference/render_html.md) -
Main HTML rendering function (used for both register and non-register
tables) -
[`generate_html_document_yml()`](http://codecheck.org.uk/codecheck/reference/generate_html_document_yml.md) -
Creates YAML config for Pandoc with header/prefix/postfix includes -
[`create_index_section_files()`](http://codecheck.org.uk/codecheck/reference/create_index_section_files.md) -
Creates HTML header, prefix, and postfix from templates -
[`create_index_postfix_html()`](http://codecheck.org.uk/codecheck/reference/create_index_postfix_html.md) -
Creates postfix with links to CSV/JSON/MD versions using Whisker
templating -
[`generate_href()`](http://codecheck.org.uk/codecheck/reference/generate_href.md) -
Constructs URLs based on `CONFIG$HREF_DETAILS` and filter/subcat -
[`edit_html_lib_paths()`](http://codecheck.org.uk/codecheck/reference/edit_html_lib_paths.md) -
Modifies HTML to use shared `docs/libs/` folder (avoids duplication)

**R/utils_render_register_json.R** - JSON generation: -
[`render_register_json()`](http://codecheck.org.uk/codecheck/reference/render_register_json.md) -
Creates three JSON files per view: - `register.json` - Full register
with all entries - `featured.json` - Last N entries (N from
`CONFIG$FEATURED_COUNT`, default 10) - `stats.json` - Metadata (source
URL, cert count) -
[`add_repository_links_json()`](http://codecheck.org.uk/codecheck/reference/add_repository_links_json.md) -
Converts repository specs to full URLs -
[`set_paper_title_references()`](http://codecheck.org.uk/codecheck/reference/set_paper_title_references.md) -
Extracts paper titles and references from codecheck.yml - Uses
`CONFIG$JSON_COLUMNS` to determine which columns to include

**R/utils_render_table_venues.R** - Venue list generation: -
[`create_venues_tables()`](http://codecheck.org.uk/codecheck/reference/create_venues_tables.md) -
Creates “all venues” table + one table per venue type -
[`create_all_venues_table()`](http://codecheck.org.uk/codecheck/reference/create_all_venues_table.md) -
Lists all venues with type and codechecks count -
[`create_venue_type_tables()`](http://codecheck.org.uk/codecheck/reference/create_venue_type_tables.md) -
Creates separate table for each venue type (journal, conference,
community, institution) -
[`add_venues_hyperlinks_non_reg()`](http://codecheck.org.uk/codecheck/reference/add_venues_hyperlinks_non_reg.md) -
Adds markdown links to venue pages and “see all checks” links - Uses
`CONFIG$DICT_VENUE_NAMES` to map short names to display names - Uses
`CONFIG$VENUE_SUBCAT_PLURAL` for URL construction (conference →
conferences)

**R/utils_render_table_codecheckers.R** - Codechecker list generation: -
[`create_all_codecheckers_table()`](http://codecheck.org.uk/codecheck/reference/create_all_codecheckers_table.md) -
Creates table with codechecker name, ORCID, and codechecks count -
Unnests Codechecker column (each codecheck can have multiple
codecheckers) -
[`add_all_codecheckers_hyperlink()`](http://codecheck.org.uk/codecheck/reference/add_all_codecheckers_hyperlink.md) -
Adds links to codechecker pages, ORCID profiles, and “see all checks”
links

**R/utils_render_table_non_registers.R** - Non-register page
orchestration: -
[`create_non_register_files()`](http://codecheck.org.uk/codecheck/reference/create_non_register_files.md) -
Creates HTML and JSON for venue/codechecker summary pages -
[`create_tables_non_register()`](http://codecheck.org.uk/codecheck/reference/create_tables_non_register.md) -
Dispatches to venue or codechecker table creator -
[`generate_table_details_non_reg()`](http://codecheck.org.uk/codecheck/reference/generate_table_details_non_reg.md) -
Creates metadata with title, subtext, extra_text -
[`render_non_register_md()`](http://codecheck.org.uk/codecheck/reference/render_non_register_md.md) -
Creates markdown for non-register pages -
[`generate_html_title_non_registers()`](http://codecheck.org.uk/codecheck/reference/generate_html_title_non_registers.md) -
Uses functions from `CONFIG$NON_REG_TITLE_FNS` -
[`generate_html_subtext_non_register()`](http://codecheck.org.uk/codecheck/reference/generate_html_subtext_non_register.md) -
Generates summary text (e.g., “In total, 100 codechecks…”) -
[`generate_html_extra_text_non_register()`](http://codecheck.org.uk/codecheck/reference/generate_html_extra_text_non_register.md) -
Adds explanatory text (used for codechecker page)

**R/utils_register_check.R** - Validation functions: -
[`check_certificate_id()`](http://codecheck.org.uk/codecheck/reference/check_certificate_id.md) -
Compares certificate ID in register.csv vs codecheck.yml -
[`check_issue_status()`](http://codecheck.org.uk/codecheck/reference/check_issue_status.md) -
Verifies GitHub issue exists and checks its state

**R/utils_download_certs.R** - Certificate PDF downloads: -
[`download_cert_pdf()`](http://codecheck.org.uk/codecheck/reference/download_cert_pdf.md) -
Downloads certificate PDF from Zenodo DOI - Handles different Zenodo URL
formats and API responses

#### 2.4. Configuration System (inst/extdata/config.R)

The CONFIG environment stores all configuration as lists/vectors. Key
elements:

**Table structure:** - `CONFIG$REGISTER_COLUMNS` - Hierarchical column
configuration: filter → file_type → columns - Special filter “default”
used for main register and as fallback - Filter-specific configs (e.g.,
“venues”, “codecheckers”) can override defaults - Supports different
column orders and selections per view - Example:
`CONFIG$REGISTER_COLUMNS$default$html` or
`CONFIG$REGISTER_COLUMNS$venues$json` -
`CONFIG$MD_TABLE_COLUMN_WIDTHS` - Markdown column width specifications
for register and non-register tables - `CONFIG$JSON_COLUMNS` - Column
order for JSON output (featured.json and main register.json)

**Filtering:** - `CONFIG$FILTER_COLUMN_NAMES` - Maps filter name to
register column (venues→Venue, codecheckers→Codechecker) -
`CONFIG$FILTER_SUBCAT_COLUMNS` - Maps filter to subcat column
(venues→Type) - `CONFIG$FILTER_SUBCATEGORIES` - Lists subcats per filter
(venues→\[community, journal, conference, institution\])

**URLs and hyperlinks:** - `CONFIG$HYPERLINKS` - Base URLs for all
platforms (GitHub, OSF, GitLab, Zenodo, ORCID, DOI, etc.) -
`CONFIG$HREF_DETAILS` - Specs for generating links (base_url, file
extension) for CSV/JSON/MD downloads - `CONFIG$CERT_LINKS` - API URLs
for OSF, Zenodo, CrossRef, OpenAlex

**Display settings:** - `CONFIG$DICT_VENUE_NAMES` - Maps short names to
full display names (e.g., “GigaScience” → “GigaScience”) -
`CONFIG$VENUE_SUBCAT_PLURAL` - Pluralization map
(conference→conferences, journal→journals) -
`CONFIG$NON_REG_TABLE_COL_NAMES` - Column name mappings for venues and
codecheckers tables - `CONFIG$DICT_ORCID_ID_NAME` - Built dynamically
during preprocessing; maps ORCID to name

**Titles and text:** - `CONFIG$MD_TITLES` - Functions that generate
titles for different page types - `CONFIG$NON_REG_TITLE_FNS` - Functions
that generate titles for venue/codechecker pages -
`CONFIG$NON_REG_SUBTEXT` - Functions that generate summary text -
`CONFIG$NON_REG_EXTRA_TEXT` - Additional explanatory text for specific
pages

**Certificates:** - `CONFIG$CERT_DPI` - Resolution for PDF-to-PNG
conversion (default: 800) - `CONFIG$CERT_REQUEST_DELAY` - Delay between
Zenodo requests in seconds (default: 1) -
`CONFIG$CERT_DOWNLOAD_AND_CONVERT` - Boolean to enable/disable PDF
downloads - `CONFIG$FEATURED_COUNT` - Number of certificates in
featured.json (default: 10)

**Directories:** - `CONFIG$CERTS_DIR` - Paths to certificate templates
and output directory - `CONFIG$TEMPLATE_DIR` - Paths to all template
files (reg, non_reg, cert, general) -
`CONFIG$DIR_TEMP_REGISTER_CODECHECKER` - Temporary CSV path for
codechecker filtering

**Runtime state:** - `CONFIG$NO_CODECHECKS` - Total number of codechecks
(set during preprocessing) - `CONFIG$NO_CODECHECKS_VENUE_TYPE` -
Codechecks count per venue type (set during venue table creation)

#### 2.5. Template System

Templates are located in `inst/extdata/templates/` with separate
subdirectories:

**Register tables** (`reg_tables/`): - `template.md` - Markdown template
with `$title$` and `$content$` placeholders -
`index_postfix_template.html` - HTML footer with download links
(CSV/JSON/MD) - Uses Whisker templating for dynamic links

**Non-register tables** (`non_reg_tables/`): - `template.md` - Markdown
template with `$title$`, `$subtitle$`, `$content$`, `$extra_text$` -
`index_postfix_template.html` - HTML footer with JSON link

**Certificate pages** (`cert/`): - `template_base.md` - Full template
with certificate PDF display - `template_no_cert.md` - Template when PDF
unavailable - `template_cert_page.html` - HTML wrapper (currently
unused) - Placeholders: `$title$`, `$paper_title$`, `$paper_authors$`,
`$abstract_content$`, `$codechecker_names$`, `$codecheck_time$`,
`$codecheck_summary$`, `$codecheck_cert$`, `$codecheck_repo$`,
`$codecheck_full_certificate$`

**General** (`general/`): - `index_header_template.html` - HTML header
with meta tags, CSS links - `index_prefix_template.html` - HTML prefix
with navigation and branding

All HTML files use Pandoc/rmarkdown for Markdown→HTML conversion with
custom YAML configs.

#### 2.6. Output Directory Structure

The rendering process creates this directory structure in `docs/`:

    docs/
    ├── index.html                    # Main register page
    ├── register.md                   # Markdown version
    ├── register.json                 # Full JSON
    ├── featured.json                 # Last 10 certificates
    ├── stats.json                    # Statistics
    ├── libs/                         # Shared JS/CSS libraries
    ├── certs/                        # Certificate pages
    │   ├── 2024-001/
    │   │   ├── index.html
    │   │   ├── cert.pdf
    │   │   ├── cert_1.png
    │   │   ├── cert_2.png
    │   │   └── ...
    │   └── 2024-002/
    │       └── ...
    ├── venues/                       # Venue-filtered registers
    │   ├── index.html                # All venues list
    │   ├── index.json
    │   ├── journals/
    │   │   ├── index.html            # Journal list
    │   │   ├── gigascience/
    │   │   │   ├── index.html        # GigaScience register
    │   │   │   ├── register.csv
    │   │   │   ├── register.md
    │   │   │   └── register.json
    │   │   └── j_geogr_syst/
    │   │       └── ...
    │   ├── conferences/
    │   │   └── ...
    │   ├── communities/
    │   │   └── ...
    │   └── institutions/
    │       └── ...
    └── codecheckers/                 # Codechecker-filtered registers
        ├── index.html                # All codecheckers list
        ├── index.json
        ├── 0000-0001-2345-6789/
        │   ├── index.html            # Individual codechecker register
        │   ├── register.csv
        │   ├── register.md
        │   └── register.json
        └── ...

#### 2.7. Relationship with ../register Repository

The `../register` repository is the **data and deployment repository**
that contains: - `register.csv` - The master list of all codechecks -
`Makefile` - Commands for rendering (calls functions from this R
package) - `docs/` - All generated output files (committed to git,
served via GitHub Pages) - `.github/workflows/` - GitHub Actions that
automatically render on changes

**Workflow**: 1. User edits `register.csv` in the `../register`
repository 2. GitHub Action or manual `make render` calls
[`codecheck::register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
3. R package reads `register.csv`, fetches remote `codecheck.yml` files,
generates all output formats 4. Output is written to `../register/docs/`
5. Changes are committed and deployed to
<https://codecheck.org.uk/register/>

**Testing locally**:

``` r
# From within the ../register directory:
R -q -e "codecheck::register_render(); warnings()"

# Check specific entries:
R -q -e "codecheck::register_check(); warnings()"

# Clear cache after updating remote codecheck.yml:
R -q -e "codecheck::register_clear_cache()"

# Render only recent entries:
register <- read.csv('register.csv', as.is = TRUE, comment.char = '#')
codecheck::register_render(from = nrow(register) - 5, to = nrow(register))
```

#### 2.8. Important Implementation Details

**Caching**: All remote `codecheck.yml` files are cached using
[`R.cache::addMemoization()`](https://rdrr.io/pkg/R.cache/man/addMemoization.html)
to avoid repeated network requests. Cache location: `~/.Rcache/`. Clear
with
[`register_clear_cache()`](http://codecheck.org.uk/codecheck/reference/register_clear_cache.md).

**Rate limiting**: - GitHub API: Requires `GITHUB_PAT` environment
variable to avoid rate limits (60 req/hour without token, 5000/hour
with) - Zenodo API: Respects 1-second delay between requests
(configurable via `CONFIG$CERT_REQUEST_DELAY`)

**Library path management**: All HTML files use a shared `docs/libs/`
folder for Bootstrap/jQuery/etc. The function
[`edit_html_lib_paths()`](http://codecheck.org.uk/codecheck/reference/edit_html_lib_paths.md)
rewrites `"libs/` to relative paths like `"../../libs/` to avoid
duplicating libraries in every subdirectory.

**PDF handling**: Certificate PDFs are downloaded from Zenodo and
converted to PNG images using
[`pdftools::pdf_convert()`](https://docs.ropensci.org/pdftools//reference/pdf_render_page.html)
at 800 DPI. The certificate page template includes JavaScript for image
carousel/navigation.

**Codechecker column handling**: The Codechecker column contains R lists
(each codecheck can have multiple codecheckers). For CSV export and
grouping, the column is “flattened” by unnesting: one row with two
codecheckers becomes two rows, each with one codechecker. This is why
the sum of individual codechecker’s codechecks exceeds the total number
of codechecks.

**Venue name standardization**: Short names in `register.csv` (e.g., “J
Geogr Syst”) are mapped to full display names (e.g., “Journal of
Geographical Systems”) via `CONFIG$DICT_VENUE_NAMES`. URLs use slugified
versions (`j_geogr_syst`).

**Abstract retrieval**: Abstracts are fetched in this order: 1. CrossRef
API (primary source) 2. OpenAlex API (fallback, uses inverted index
format) 3. If both fail, no abstract is shown

**Markdown to HTML rendering**: Uses
[`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
with custom YAML config files that specify HTML includes (header,
prefix, postfix). Pandoc processes the markdown with Bootstrap styling.

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

# Changelog

## codecheck 0.25.0

### Bug Fixes

- **Fixed navigation links on venue type pages**: Corrected navigation
  menu links on venue type-specific pages (e.g.,
  `/venues/institutions/`, `/venues/communities/`). The “All Venues”
  link now correctly points to `../index.html` (one level up), and “All
  Codecheckers” link points to `../../codecheckers/index.html` (up two
  levels then into codecheckers). Previously these links were broken
  because they were using the generic base_path calculation
- **Fixed navigation and logo paths on venue type pages**: Corrected
  base path calculation for venue type-specific pages (e.g.,
  `/venues/institutions/`, `/venues/journals/`). These pages are two
  levels deep, but were incorrectly treated as one level deep, causing
  broken logo and navigation links. The
  [`calculate_breadcrumb_base_path()`](http://codecheck.org.uk/codecheck/reference/calculate_breadcrumb_base_path.md)
  function now correctly handles non-register table pages with
  subcategories
- **Removed venue label column from venue type pages**: The “venue
  label” column (showing GitHub issue labels) is no longer displayed on
  venue type-specific pages (institutions, journals, conferences,
  communities) as it provides no useful information when all venues are
  of the same type. The column is still shown on the “all venues” page
  where it helps distinguish between different venue types

### Performance & Scalability

- **Certificate identifier prefixes in logs**: All log messages during
  certificate rendering operations now include the certificate
  identifier as a prefix (e.g., “2020-001 \| Downloaded successfully”).
  This makes logs much easier to understand when rendering is executed
  in parallel, as messages from different certificates can be easily
  distinguished and tracked

## codecheck 0.24.0

### Register Enhancements

- **Relative paths for localhost development**: All internal navigation
  links in register tables and certificate pages now use relative paths
  instead of absolute URLs pointing to codecheck.org.uk. This enables
  seamless development and testing on localhost. Includes certificate
  links, venue links, venue type links, and codechecker links throughout
  the register. JSON and CSV exports continue to use absolute URLs for
  external consumption
- **Optimized table column widths**: Paper Title column width has been
  doubled for better readability, while the Report column has been
  significantly reduced. Report links now display shortened URLs
  (removing “<http://>” and “<https://>” prefixes) while maintaining
  full URLs in the underlying links. These changes improve the visual
  balance and readability of register tables
- **Expanded certificate page text sections**: Certificate pages now
  display full abstract and summary text without scrollable containers,
  allowing the “paper details” section to grow naturally to accommodate
  all content. This improves readability by eliminating the need to
  scroll within small text boxes
- **Auto-pagination for certificate images**: Certificate pages now
  automatically advance through certificate preview images every 5
  seconds when the page loads. Auto-pagination stops when users interact
  with the page (clicks or keyboard navigation), providing a helpful
  preview without interfering with manual navigation
- **Full-width certificate pages**: Certificate pages now use the full
  viewport width instead of being constrained to 1200px, providing more
  space for the two-column layout with certificate images and details.
  The header and footer maintain their 1200px max-width for consistency
  with other pages
- **Improved header logo alignment**: Navigation header logo is now
  flush left-aligned with no left margin or padding, matching the
  alignment of footer elements for visual consistency across all pages
- **Consistent sorting across all outputs**: All register outputs (HTML,
  Markdown, JSON) are now consistently sorted by certificate identifier
  for predictable ordering. The exception is featured.json which remains
  sorted by check date (most recent first) to highlight the latest
  codechecks (addresses codecheckers/register#160)
- **Citation generator on certificate pages**: Certificate landing pages
  now include an interactive citation generator powered by citation.js.
  Users can select from multiple citation formats (APA, Vancouver,
  Harvard, BibTeX, BibLaTeX, RIS) using a dropdown menu, with BibTeX as
  the default format. The citation preview updates automatically and
  includes a “Copy to clipboard” button for easy copying. Citations are
  generated from the certificate DOI, with metadata retrieved from
  data.crosscite.org (this is noted transparently on the page).
  (addresses codecheckers/register#82)
- **Selective meta generator tags**: Meta generator tags now show
  different levels of detail based on page type. Overview/list pages
  (main register, all venues, all codecheckers) display full version
  information (e.g., “codecheck 0.23.0, register commit abc123”).
  Individual detail pages (specific certificates, venues, and
  codecheckers) show only “codecheck” without version information. This
  parallels the existing approach for build metadata and avoids
  confusion about page freshness for individual resource pages
- **Centralized JavaScript libraries**: All JavaScript code is now
  centralized in dedicated files (`cert-utils.js`, `cert-citation.js`)
  loaded from `docs/libs/codecheck/`. This eliminates code duplication
  across certificate templates, improves maintainability, and ensures
  consistent behavior. The citation.js library is now bundled locally
  instead of loading from CDN, improving reliability and page load times
- **Improved navigation visibility**: Top-right navigation menu font
  size doubled for better readability. Active page link (All Venues or
  All Codecheckers) is now highlighted with bold font. Breadcrumb
  navigation font size increased by 20% for improved visibility
- **Centralized breadcrumb styling**: Breadcrumb container styling has
  been moved from inline styles to the central CSS file
  (`.breadcrumb-container` class). Left and right padding has been
  removed for cleaner alignment with page content

### Performance & Scalability

- **Parallel certificate rendering**: Certificate HTML pages can now be
  rendered in parallel using multiple CPU cores for significant
  performance improvements. The
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  function accepts two new parameters: `parallel` (logical, defaults to
  FALSE) and `ncores` (integer, auto-detects available cores minus 1 if
  NULL). On an 8-core machine, parallel rendering provides approximately
  5-6x speedup for certificate generation. Platform-specific
  implementation uses
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html) on
  Unix/Mac (memory-efficient forking) and
  [`parallel::parLapply()`](https://rdrr.io/r/parallel/clusterApply.html)
  on Windows (cluster-based). Enhanced error handling ensures individual
  certificate failures don’t stop the entire render. Timing statistics
  now include theoretical speedup and parallel efficiency metrics.
  Usage: `register_render(parallel = TRUE)` or
  `register_render(parallel = TRUE, ncores = 4)`
- **Timing instrumentation for performance analysis**: Added
  comprehensive timing instrumentation to all rendering functions
  ([`render_cert_htmls()`](http://codecheck.org.uk/codecheck/reference/render_cert_htmls.md),
  [`create_register_files()`](http://codecheck.org.uk/codecheck/reference/create_register_files.md),
  [`create_non_register_files()`](http://codecheck.org.uk/codecheck/reference/create_non_register_files.md)).
  Each function now logs start/end times with millisecond precision,
  individual item rendering times, and summary statistics (total time,
  average time per item). This enables performance profiling and
  identification of bottlenecks. Log output includes timestamps in ISO
  8601 format for easy parsing and analysis
- **Parallelization analysis and implementation guide**: Created
  comprehensive documentation
  (`inst/extdata/docs/PARALLELIZATION_ANALYSIS.md`) analyzing
  parallelization opportunities for certificate and register page
  rendering. Includes detailed analysis of current architecture, timing
  analysis methodology, three prioritized parallelization strategies,
  implementation recommendations using R’s `parallel` package, expected
  performance gains (6x speedup for certificates on 8-core machine), and
  complete working example
  (`inst/extdata/scripts/parallel_render_example.R`). Documentation
  guides through measuring current performance, implementing parallel
  execution, testing strategies, and tuning for optimal performance

### Bug Fixes

- **Fixed duplicate certificates in NA codechecker pages**: When
  multiple codecheckers without ORCID work on the same certificate, the
  certificate now appears only once in the NA codechecker page instead
  of once per NA codechecker. Implemented deduplication by keeping one
  row per unique combination of Certificate ID and Codechecker
  identifier (addresses codecheckers/register#153)
- **Codecheckers without ORCID now appear on “All codecheckers” page**:
  Fixed issue where codecheckers without ORCID identifiers were excluded
  from the main codecheckers listing. These codecheckers now appear with
  the label “Codecheckers without ORCID”, with an empty ORCID column,
  and link to the `/codecheckers/NA/` page showing all their codechecks.
  If a codechecker has a GitHub username registered in the codecheckers
  repository, that username is used as their identifier instead of “NA”
- **Fixed NA check date handling in schema.org metadata**: Added
  `!is.na()` check in
  [`generate_codechecker_schema_org()`](http://codecheck.org.uk/codecheck/reference/generate_codechecker_schema_org.md)
  to prevent “missing value where TRUE/FALSE needed” error when Check
  date column contains NA values
- **Exported
  [`generate_cert_json()`](http://codecheck.org.uk/codecheck/reference/generate_cert_json.md)
  function**: Fixed test failures by adding `@export` tag to make the
  [`generate_cert_json()`](http://codecheck.org.uk/codecheck/reference/generate_cert_json.md)
  function available for testing and external use. The function
  generates index.json files for certificate pages containing all
  certificate metadata in machine-readable format
- **Fixed citation generator loading**: Completely rewrote the citation
  library loading system to be simpler and more reliable. Created
  `citation-wrapper.js` to expose the Cite object globally from the
  browserify bundle (citation.js from npm uses CommonJS modules and
  doesn’t expose globals). Simplified initialization code by removing
  complex polling mechanism - Cite is now immediately available after
  wrapper loads. Added comprehensive documentation
  (`inst/extdata/scripts/JAVASCRIPT_LIBRARIES.md`) and download script
  (`inst/extdata/scripts/download-js-libraries.sh`) for managing
  JavaScript libraries locally without CDN dependencies. This fixes the
  “Loading citation…” indefinitely issue

## codecheck 0.23.0 (2025-11-12)

### Register Enhancements

- **Navigation header with logo**: All register pages now feature a
  navigation header with the CODECHECK logo in the top left, which
  serves as a home link back to the main register. Overview pages (main
  register, all venues, all codecheckers) include a menu in the top
  right with links to “All Venues”, “All Codecheckers”, and “About”
  (linking to the main CODECHECK website) for quick navigation
- **Breadcrumb navigation**: All register pages now include breadcrumb
  navigation at the top, enabling easy navigation from detail pages back
  to overview pages. Breadcrumbs show hierarchical paths (e.g.,
  CODECHECK Register \> Venues \> Journals \> GigaScience) with
  clickable links to parent pages (addresses codecheckers/register#108)
- **JSON data export for certificates**: Certificate landing pages now
  include an `index.json` file containing all metadata displayed on the
  page in machine-readable format. The JSON structure includes
  certificate details, paper information (title, authors with ORCID,
  reference, abstract), and CODECHECK details (codecheckers with ORCID,
  check time, repository, report, type, venue, summary, manifest). A
  link to the JSON file is displayed at the bottom of each certificate
  page for programmatic access (addresses codecheckers/register#143)
- **Schema.org metadata for certificates**: Certificate landing pages
  now include structured Schema.org JSON-LD metadata in the HTML header.
  The certificate is represented as a Review entity with the paper as a
  ScholarlyArticle entity (via itemReviewed property). Includes all
  available information: paper title/authors/abstract/DOI, codecheckers
  with ORCID, check date, summary, and certificate PDF URL (as
  MediaObject). Metadata validates successfully with
  validator.schema.org. Enables better discoverability by search engines
  and tools that consume schema.org metadata (addresses
  codecheckers/register#182)
- **Schema.org metadata for codechecker pages**: Codechecker profile
  pages now include structured Schema.org JSON-LD metadata in the HTML
  header. The codechecker is represented as a Person entity with an
  array of Review entities representing all their codechecks. Each
  Review includes the certificate details and optionally includes the
  paper being reviewed (ScholarlyArticle with title, authors, DOI).
  Person entity includes ORCID identifier and optional GitHub profile
  link (via sameAs property). Enables better discoverability of
  codechecker profiles and their work by search engines and research
  tools
- **Configurable field ordering**: Register views now support per-filter
  column configuration, allowing different field orders and selections
  for main register vs. filtered views (venues, codecheckers). Main
  register now displays columns in the order: Certificate, Report,
  Title, Venue, Type, Check date (addresses
  [\#101](https://github.com/codecheckers/codecheck/issues/101))
- **Context-aware field filtering**: Filtered views automatically
  exclude redundant fields (e.g., venue/type columns hidden on
  venue-specific pages, codechecker column hidden on codechecker pages)
- **Hierarchical column configuration**: New `CONFIG$REGISTER_COLUMNS`
  structure with filter-specific overrides and automatic fallback to
  defaults for maximum flexibility
- **Enhanced CSV file fields**: CSV files now include all available
  fields matching JSON output (Certificate ID, Certificate Link,
  Repository, Repository Link, Report, Title, Paper reference, Type,
  Venue, Check date). Previously CSV files only contained Certificate
  and Repository columns. This provides more complete data for
  programmatic access and analysis
- **SEO support with sitemap.xml and robots.txt**: Register rendering
  now automatically generates sitemap.xml and robots.txt files for
  improved search engine optimization and discoverability. Sitemap
  includes all generated pages (main register, venue pages, codechecker
  pages, certificate pages) with appropriate priorities and change
  frequencies. Robots.txt allows all search engines to crawl the
  register (addresses codecheckers/register#126)
- **GitHub username support for codecheckers without ORCID**:
  Codecheckers without ORCID now get their own pages using their GitHub
  username as the identifier (e.g., `/codecheckers/username/`). For
  codecheckers with ORCID, a redirect page is automatically created at
  their GitHub username URL that redirects to their ORCID-based page.
  This ensures all codecheckers are listed in the register regardless of
  whether they have an ORCID. Redirect pages use the main CSS and
  include the standard header/footer for consistent branding (addresses
  codecheckers/register#130)
- **Relative asset links**: Favicon and CSS stylesheet links in HTML
  headers now use relative paths calculated based on each page’s depth,
  eliminating hard-coded absolute URLs and improving portability
- **Build metadata in footer**: Overview/listing pages (main register,
  all venues list, all codecheckers list) now display build information
  in muted text at the bottom of the footer, including timestamp,
  package version, codecheck package commit, and register commit with
  GitHub links. Build info is intentionally omitted from individual
  certificate, venue, and codechecker pages to avoid confusion about
  page freshness (addresses
  [\#105](https://github.com/codecheckers/codecheck/issues/105))
- **Dual commit tracking**: Footer now displays both codecheck package
  commit and register repository commit as clickable links to respective
  GitHub commits
- **Meta generator tag**: HTML pages now include a properly formatted
  `<meta name="generator">` tag with package version and commit
  information (fixed display issue)
- **Build metadata JSON**: A `.meta.json` file is now generated at the
  root of the docs directory containing build metadata for both
  repositories
- **Icon font usage**: Replaced inline SVG logos with academicons and
  Font Awesome icon fonts for ORCID, GitHub, and Zenodo for cleaner HTML
  and easier maintenance
- **Template-based HTML generation**: Moved HTML structure from R
  functions to template files, keeping R code focused on data
  preparation
- **Codechecker profile links**: Individual codechecker pages now
  display ORCID and GitHub profile links above the table, pulling data
  from the codecheckers/codecheckers repository (addresses
  [\#73](https://github.com/codecheckers/codecheck/issues/73))
- **ORCID branding compliance**: Codechecker pages now use the official
  ORCID iD logo and display full ORCID URLs (<https://orcid.org/>…) as
  required by ORCID brand guidelines
- **Simplified codechecker titles**: Removed ORCID identifier from
  codechecker page titles for cleaner display (titles now show just
  “Codechecks by \[Name\]”)
- **Zenodo community link**: Added link to CODECHECK Zenodo Community in
  footer of all register pages alongside the GitHub organization link

### Bug Fixes

- **Fixed venue label error**: Resolved “venue_label must be size 1, not
  12” error by ungrouping data frame before venue_label mutation in
  [`create_all_venues_table()`](http://codecheck.org.uk/codecheck/reference/create_all_venues_table.md)
- **Fixed NA codechecker handling** (superseded in development version):
  Codecheckers without ORCID identifiers were temporarily filtered out
  during register rendering to prevent duplicate entries. This has been
  replaced with proper deduplication logic in the development version
- **Fixed NULL paper title handling**: Added NULL check in
  [`set_paper_title_references_csv()`](http://codecheck.org.uk/codecheck/reference/set_paper_title_references_csv.md)
  to prevent “missing value where TRUE/FALSE needed” error when paper
  titles are NULL during CSV generation
- **Fixed icon font paths**: Icon font CSS links (academicons,
  font-awesome) in HTML header now use `{{base_path}}` variable for
  correct relative paths on all pages (root, venue, codechecker pages).
  Previously hardcoded `libs/` path only worked on root index page
- **Fixed JavaScript/CSS loading**: Fixed two critical bugs in
  [`edit_html_lib_paths()`](http://codecheck.org.uk/codecheck/reference/edit_html_lib_paths.md):
  1.  Updated regex pattern to match any relative path to libs folder
      (libs/, ../libs/, ../../libs/, etc.) instead of only matching
      exact “libs/”
  2.  Added filtering of empty path components caused by double slashes
      (e.g., “docs/codecheckers/ID//index.html”) which caused incorrect
      relative path calculation (../../../ instead of ../../) These
      fixes resolve “\$ is not defined” errors and broken CSS styling on
      venue, codechecker, and certificate pages
- **Fixed navbar logo paths**: Navigation header logo now correctly
  handles relative paths on all pages. For root page, logo path is now
  `codecheck_logo.svg` instead of `./codecheck_logo.svg` to avoid
  browser compatibility issues. Deeper pages use proper relative paths
  (`../codecheck_logo.svg`, `../../codecheck_logo.svg`, etc.)

### New Functions

- **[`generate_navigation_header()`](http://codecheck.org.uk/codecheck/reference/generate_navigation_header.md)**:
  Generates navigation header HTML with CODECHECK logo and conditional
  menu (menu shown only on main register page)
- **[`generate_breadcrumb()`](http://codecheck.org.uk/codecheck/reference/generate_breadcrumb.md)**:
  Generates Bootstrap-styled breadcrumb navigation HTML based on page
  context (filter type, table details, and relative path)
- **[`calculate_breadcrumb_base_path()`](http://codecheck.org.uk/codecheck/reference/calculate_breadcrumb_base_path.md)**:
  Calculates relative path to register root based on page depth for
  breadcrumb links
- **[`get_build_metadata()`](http://codecheck.org.uk/codecheck/reference/get_build_metadata.md)**:
  Retrieves build metadata including timestamp, package version, and git
  commit information from both register and codecheck package
  repositories
- **[`generate_meta_generator_content()`](http://codecheck.org.uk/codecheck/reference/generate_meta_generator_content.md)**:
  Creates meta generator content value (replaces
  `generate_meta_generator_tag()` to separate content from HTML
  structure)
- **[`generate_footer_build_info()`](http://codecheck.org.uk/codecheck/reference/generate_footer_build_info.md)**:
  Generates HTML for displaying build information in page footers
  including both codecheck and register commits with GitHub links
- **[`write_meta_json()`](http://codecheck.org.uk/codecheck/reference/write_meta_json.md)**:
  Writes build metadata to .meta.json file in specified directory
- **[`get_codecheckers_data()`](http://codecheck.org.uk/codecheck/reference/get_codecheckers_data.md)**:
  Fetches and caches codecheckers registry from
  codecheckers/codecheckers repository
- **[`get_codechecker_profile()`](http://codecheck.org.uk/codecheck/reference/get_codechecker_profile.md)**:
  Retrieves profile information (name, GitHub handle, ORCID, fields,
  languages) by ORCID
- **[`generate_codechecker_profile_links()`](http://codecheck.org.uk/codecheck/reference/generate_codechecker_profile_links.md)**:
  Generates HTML for horizontal list of profile links with icons
- **[`add_repository_links_csv()`](http://codecheck.org.uk/codecheck/reference/add_repository_links_csv.md)**:
  Adds “Repository Link” column to register table for CSV export,
  converting platform specs (e.g., “github::org/repo”) to full URLs
- **[`set_paper_title_references_csv()`](http://codecheck.org.uk/codecheck/reference/set_paper_title_references_csv.md)**:
  Extracts plain text “Title” and “Paper reference” columns from
  hyperlinked “Paper Title” for CSV export
- **[`generate_sitemap()`](http://codecheck.org.uk/codecheck/reference/generate_sitemap.md)**:
  Generates sitemap.xml file listing all register pages with priorities
  and change frequencies for search engine optimization
- **[`generate_robots_txt()`](http://codecheck.org.uk/codecheck/reference/generate_robots_txt.md)**:
  Generates robots.txt file allowing all search engines to crawl the
  register and referencing the sitemap
- **[`get_codechecker_profile_by_handle()`](http://codecheck.org.uk/codecheck/reference/get_codechecker_profile_by_handle.md)**:
  Retrieves codechecker profile information by GitHub username (handle)
- **[`get_github_handle_by_name()`](http://codecheck.org.uk/codecheck/reference/get_github_handle_by_name.md)**:
  Looks up GitHub username for a codechecker by their full name from the
  codecheckers registry
- **[`generate_codechecker_redirect()`](http://codecheck.org.uk/codecheck/reference/generate_codechecker_redirect.md)**:
  Creates HTML redirect page at GitHub username URL that redirects to
  ORCID-based page for codecheckers with both identifiers
- **[`generate_codechecker_redirects()`](http://codecheck.org.uk/codecheck/reference/generate_codechecker_redirects.md)**:
  Iterates through all codecheckers in register and creates redirect
  pages for those with both ORCID and GitHub username
- **[`generate_cert_json()`](http://codecheck.org.uk/codecheck/reference/generate_cert_json.md)**:
  Generates index.json file for certificate landing pages containing all
  metadata in machine-readable format (certificate, paper, CODECHECK
  details including abstract, summary, and manifest)
- **[`generate_cert_schema_org()`](http://codecheck.org.uk/codecheck/reference/generate_cert_schema_org.md)**:
  Generates Schema.org JSON-LD for certificate landing pages,
  representing the CODECHECK certificate as a Review of a
  ScholarlyArticle with all available metadata (paper
  title/authors/abstract/DOI, codecheckers with ORCID, check date,
  summary, certificate PDF URL)
- **[`generate_codechecker_schema_org()`](http://codecheck.org.uk/codecheck/reference/generate_codechecker_schema_org.md)**:
  Generates Schema.org JSON-LD for codechecker profile pages,
  representing the codechecker as a Person with an array of Review
  entities for all their codechecks. Each Review optionally includes the
  paper being reviewed (ScholarlyArticle). Supports optional GitHub
  profile link via sameAs property

### Tests

- **Schema.org metadata generation for certificates**: Added
  comprehensive test suite (`test_schema_org_generation.R`) with 43 test
  cases covering:
  - JSON-LD structure and validity
  - Review and ScholarlyArticle types
  - Author/codechecker handling with and without ORCID
  - Paper metadata (title, abstract, DOI)
  - Optional fields (summary, abstract, report URL)
  - Date parsing and formatting
  - Edge cases (single author, missing fields, empty strings)
- **Schema.org metadata generation for codecheckers**: Added
  comprehensive test suite (`test_schema_org_codechecker.R`) with 17
  test cases covering:
  - Person entity structure with ORCID [@id](https://github.com/id)
  - Review array generation from register table
  - GitHub sameAs link handling (NULL, empty string, “NA”)
  - Check date parsing and formatting
  - Single and multiple codechecks
  - Edge cases (missing dates, empty tables)
  - JSON-LD validity for schema.org validator
  - Schema.org validator compliance

### Documentation

- **Comprehensive register rendering documentation**: Expanded CLAUDE.md
  with detailed documentation of the register rendering system,
  including:
  - Complete rendering pipeline flow
  - Detailed descriptions of all 13 utility files
  - Configuration system documentation
  - Template system details
  - Output directory structure
  - Important implementation details
- **Version management guide**: Added version management section to
  CLAUDE.md with procedures for bumping versions and release workflow

## codecheck (development version)

### Certificate Page Improvements

- **Fixed codechecker links**: Codechecker names on certificate pages
  now link to their register landing pages (e.g.,
  `/register/codecheckers/0000-0001-2345-6789/`) instead of ORCID
  profiles, making it easier to see all codechecks by that person (fixes
  [\#141](https://github.com/codecheckers/codecheck/issues/141))
- **Added Type and Venue links**: Certificate pages now display
  clickable links for both the venue type and venue name in the
  CODECHECK Details section, enabling easier navigation to filtered
  register views (e.g., `/register/venues/journals/` and
  `/register/venues/journals/gigascience/`) (fixes
  [\#142](https://github.com/codecheckers/codecheck/issues/142))
- **Venue-based breadcrumb navigation**: Certificate pages now include
  breadcrumb navigation showing the venue hierarchy (e.g., CODECHECK
  Register \> Venues \> Journals \> GigaScience \> 2024-001), enabling
  easy navigation to the venue’s register page with a single click

### Visual Improvements

- **ORCID brand color**: ORCID icons on codechecker profile pages now
  display in the official ORCID green (#A6CE39) for proper brand
  compliance
- **Updated Zenodo icon**: Replaced the Zenodo icon with the official
  blue “Z” SVG from EPFL, providing a more recognizable and polished
  appearance in register page footers
- **Improved icon alignment**: Applied vertical alignment adjustments
  (`-5px`) to Zenodo, GitHub, and ORCID icons across all register pages
  for better alignment with adjacent text

### Infrastructure Improvements

- **Cleaner output directories**: Temporary HTML section files
  (index_header.html, index_prefix.html, index_postfix.html,
  html_document.yml) are now automatically removed after rendering, as
  their content is already embedded in the final index.html file
- **Separated CSS styles**: Moved all register-specific CSS styles from
  inline `<style>` tags to a dedicated `codecheck-register.css` file in
  `docs/assets/`, improving maintainability and reducing HTML file
  sizes. The CSS file is automatically copied from package templates
  during register rendering.
- **Improved path construction**: Replaced string concatenation
  (`paste0`) with [`file.path()`](https://rdrr.io/r/base/file.path.html)
  for all file system path construction throughout the codebase,
  ensuring cross-platform compatibility and following R best practices
  (addresses codecheckers/register#70)
- **Local library management**: Removed all external CDN dependencies
  (Bootstrap, Font Awesome, Academicons) and implemented local library
  management system
- **New function**: Added
  [`setup_external_libraries()`](http://codecheck.org.uk/codecheck/reference/setup_external_libraries.md)
  to download and install CSS/JS libraries locally in `docs/libs/`,
  ensuring reproducibility and offline capability
- **Provenance tracking**: All external libraries now include
  comprehensive provenance information (version, license, date
  configured) stored in `docs/libs/PROVENANCE.csv`
- **Automatic setup**: Libraries are automatically downloaded during
  register rendering if not already present
- **Documentation**: Generated README.md in `docs/libs/` documenting all
  installed libraries and their licenses

### Bug Fixes

- **Fixed register rendering error**: Fixed “missing value where
  TRUE/FALSE needed” error when rendering register pages by adding
  proper NULL check for table_details\[\[“name”\]\]
- **Fixed venue type hyperlinks**: Fixed venue type links in venue lists
  that were rendering as Markdown syntax instead of proper HTML links
  due to missing closing parenthesis

### Venue Configuration and Label Integration

- **Dynamic venue configuration**: Venue information is now loaded from
  a `venues.csv` file instead of being hardcoded in `config.R`, making
  it easier to add and manage venues
- **GitHub label integration**: Venue lists now include GitHub issue
  labels for each venue, enabling direct links to open checks
- **Enhanced JSON output**: The venues JSON at
  `/register/venues/index.json` now includes an “Issue label” field for
  each venue
- **Open checks links**: Venue HTML pages now display links to view open
  GitHub issues for each venue using their corresponding label
- **New function**: Added
  [`load_venues_config()`](http://codecheck.org.uk/codecheck/reference/load_venues_config.md)
  to load venue configuration from CSV files with columns: `name`,
  `longname`, and `label`
- **Register repository**: Created `venues.csv` in the register
  repository to store venue metadata and GitHub labels
- **Test updates**: All tests updated to work with the new venue
  configuration system using test fixtures
- **Breaking change**:
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  now requires a `venues_file` parameter (defaults to “venues.csv” in
  the working directory)

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

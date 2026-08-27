# Changelog

## codecheck 0.25.0.9012

### New Features

- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now checks the register newest-first by default (closes
  codecheckers/codecheck#79). Pass `from = 1, to = nrow(register)` for
  the previous oldest-first order.
- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now also checks the checked repository itself: organisation/group
  membership, archived status, CODECHECK badge, license, and `codecheck`
  topic tag (closes codecheckers/codecheck#25,
  [\#75](https://github.com/codecheckers/codecheck/issues/75),
  [\#14](https://github.com/codecheckers/codecheck/issues/14)).
- The allowed GitHub organisations/GitLab groups for
  [`check_repository_org()`](http://codecheck.org.uk/codecheck/reference/check_repository_org.md)
  are now configurable via `CONFIG$ALLOWED_REPO_ORGS`;
  `github.com/reproducible-agile` was added to the default list.
- [`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md)
  now checks that `codecheck.yml` is valid UTF-8, starts with the YAML
  document marker, and has at least one `codechecker` entry;
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now rejects a register containing duplicate certificate IDs (closes
  codecheckers/codecheck#9).
- [`zenodo_policy_check()`](http://codecheck.org.uk/codecheck/reference/zenodo_policy_check.md)
  gained three checks: the certificate ID must appear in the deposit
  title, a non-standard certificate PDF filename is now flagged, and
  deposit membership in the Zenodo `codecheck` community is checked
  (closes codecheckers/codecheck#20).
- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  no longer accumulates stale `header-attrs-*` directories in
  `docs/libs`, and gained
  [`prune_libs()`](http://codecheck.org.uk/codecheck/reference/prune_libs.md)
  to remove other unreferenced library directories (closes
  codecheckers/codecheck#89).
- Zenodo concept DOI checking is extended to also catch an outdated
  version-specific DOI, via new
  [`is_zenodo_latest_version()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_latest_version.md)
  (closes codecheckers/codecheck#36).

### Bug Fixes

- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  no longer aborts the whole run when Zenodo’s search endpoint
  rate-limits it; the underlying calls are now paced, share one
  connection per run instead of reconnecting for every entry, and are
  retried automatically.
- [`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  and
  [`is_zenodo_latest_version()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_latest_version.md)
  no longer double-log every Zenodo API step.
- [`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  no longer misreports a rate-limited lookup as a concept DOI; both
  functions now use `ZENODO_TOKEN` when set for a higher rate limit.
- [`is_zenodo_latest_version()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_latest_version.md)
  no longer misreports a record’s own latest version as outdated: it
  compared record IDs against a second, search-based lookup that is not
  reliably ordered by version, and could return a stale record even when
  the checked one was in fact current. It now reads the authoritative
  `is_latest` flag already present on the record itself, which is also
  one fewer request per check.
- `rprojroot` is now declared as a package dependency, fixing a
  missing-function error on a clean install.

## codecheck 0.25.0.9011

### New Features

- Zenodo “concept DOIs” are now rejected in the `report` field of
  `codecheck.yml` (closes codecheckers/codecheck#36).
- A Quarto certificate template (`codecheck.qmd`) is now shipped
  alongside the R Markdown one (closes codecheckers/codecheck#29).

### Bug Fixes

- The ORCID icon on certificate pages is now clickable and links to the
  ORCID profile.
- The ORCID icon in the PDF certificate no longer silently goes missing
  (closes codecheckers/codecheck#37).
- A creator recorded as an organisation is now reported as information,
  not an error, in the Zenodo curation policy check (raised in
  codecheckers/register#205).

## codecheck 0.25.0.9010

### Bug Fixes

- ORCID name checks no longer fail a fresh, unauthenticated workspace.
- A fresh workspace now passes strict CrossRef and ORCID name validation
  out of the box.

### New Features

- Licence correction now keeps the licences already on a Zenodo record
  when adding the required CC-BY 4.0.

## codecheck 0.25.0.9009

### Bug Fixes

- The register CSS is now written to the output directory rather than
  the working directory.

## codecheck 0.25.0.9008

### Bug Fixes

- [`create_codecheck_files()`](http://codecheck.org.uk/codecheck/reference/create_codecheck_files.md)
  now reports the correct target folder (closes
  [\#87](https://github.com/codecheckers/codecheck/issues/87)).

## codecheck 0.25.0.9007

### Bug Fixes

- OSF certificate retrieval now survives an OSF outage instead of
  failing with an unrelated parsing error.

## codecheck 0.25.0.9006

### Bug Fixes

- Rendering no longer rewrites `docs/libs/PROVENANCE.csv` on every run
  when nothing changed.
- A failed library download is no longer stored as if it were the
  library file.

## codecheck 0.25.0.9005

### Bug Fixes

- ResearchEquals certificates can be downloaded again after that
  platform’s API change.
- A register in which no codechecker has an ORCID or GitHub identifier
  now renders correctly.

## codecheck 0.25.0.9004

### Bug Fixes

- Zenodo curation no longer truncates titles that need a human’s review.
- A clear error message is now shown when a Zenodo token may not edit a
  record.

### New Features

- Curation findings that need human judgement (e.g. a non-standard title
  or repository) are now surfaced instead of guessed.

## codecheck 0.25.0.9003

### New Features

- New
  [`curate_register_zenodo_records()`](http://codecheck.org.uk/codecheck/reference/curate_register_zenodo_records.md)
  applies mechanical Zenodo metadata corrections across a whole register
  in one batch.
- [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  gained `creator_overrides` to control how individual creator names are
  split or kept as an organisation.

## codecheck 0.25.0.9002

### Bug Fixes

- Codecheckers are now recorded as persons, not organisations, in Zenodo
  metadata.
- Alternate identifiers are no longer silently dropped when uploading
  Zenodo metadata.
- Record titles now match the curation policy (“CODECHECK Certificate
  \<ID\>”).
- A missing or non-DOI paper reference now raises a clear warning.

### New Features

- Every Zenodo-hosted certificate is now audited against the CODECHECK
  community curation policy during
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  and
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md),
  with findings reported as a summary.
- New
  [`check_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/check_zenodo_record.md)
  and
  [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  audit and correct a single published Zenodo record’s metadata against
  the curation policy.

## codecheck 0.25.0

### New Features

- New `register-full.json` and `register-full.csv` exports contain the
  complete certificate metadata, including authors, codecheckers, and
  abstracts (closes codecheckers/register#57).
- New
  [`register_render_cert()`](http://codecheck.org.uk/codecheck/reference/register_render_cert.md)
  renders a single certificate by ID without re-rendering the whole
  register (closes codecheckers/codecheck#84).
- Visiting `/register/certs/` without a certificate ID now redirects to
  the main register page instead of showing a 404 (closes
  codecheckers/register#166).
- Rendering output now uses structured, colored logging with progress
  bars and section headers.
- Warnings raised during rendering are now collected and shown as a
  deduplicated summary at the end of the run.

### Bug Fixes

- Fixed stray `libs/` folders left behind by parallel rendering.
- Fixed broken navigation links on venue type pages.
- Fixed broken navigation and logo paths on venue type pages.
- Removed the redundant venue label column from venue type pages.

### Performance & Scalability

- Log messages during certificate rendering are now prefixed with the
  certificate ID, making parallel-render logs easier to follow.

## codecheck 0.24.0

### Register Enhancements

- Internal navigation links now use relative paths, enabling local
  development and testing.
- The Paper Title column is wider and the Report column narrower, with
  shortened displayed URLs.
- Certificate abstract and summary text now display in full, without a
  scrollable container.
- Certificate preview images now auto-paginate every 5 seconds, pausing
  on user interaction.
- Certificate pages now use the full viewport width.
- All register outputs (HTML, Markdown, JSON) are now consistently
  sorted by certificate ID, except `featured.json`, which stays sorted
  by check date (closes codecheckers/register#160).
- Certificate pages now include an interactive citation generator (APA,
  Vancouver, Harvard, BibTeX, BibLaTeX, RIS) (closes
  codecheckers/register#82).
- JavaScript is now centralized into dedicated files, and the citation
  library is bundled locally instead of loaded from a CDN.
- Navigation and breadcrumb text sizes were increased for readability.

### Performance & Scalability

- Certificate HTML can now be rendered in parallel across CPU cores via
  `register_render(parallel = TRUE)`, roughly 5-6x faster on 8 cores.

### Bug Fixes

- Fixed duplicate certificates appearing on the “no ORCID” codechecker
  page (closes codecheckers/register#153).
- Codecheckers without an ORCID now appear on the “All codecheckers”
  page.
- Fixed a crash from missing check dates in Schema.org metadata.
- Fixed the certificate JSON page generator not being available for
  external use.
- Fixed the citation generator, which previously loaded indefinitely.

## codecheck 0.23.0 (2025-11-12)

### Register Enhancements

- Added a navigation header with the CODECHECK logo, and an overview
  menu on the main register pages.
- Added breadcrumb navigation to all register pages (closes
  codecheckers/register#108).
- Certificate pages now include a machine-readable `index.json` (closes
  codecheckers/register#143).
- Certificate pages now include Schema.org JSON-LD metadata for search
  engines (closes codecheckers/register#182).
- Codechecker profile pages now include Schema.org JSON-LD metadata.
- Column ordering in register tables is now configurable per view
  (addresses
  [\#101](https://github.com/codecheckers/codecheck/issues/101)).
- CSV exports now include all fields available in the JSON output.
- Added `sitemap.xml` and `robots.txt` for search engine discoverability
  (closes codecheckers/register#126).
- Codecheckers without an ORCID now get their own page, keyed by GitHub
  username (closes codecheckers/register#130).
- Overview pages now show build metadata (timestamp, version, commit) in
  the footer (closes
  [\#105](https://github.com/codecheckers/codecheck/issues/105)).
- Replaced inline SVG icons with icon fonts for ORCID, GitHub, and
  Zenodo.
- Codechecker pages now display ORCID and GitHub profile links (closes
  [\#73](https://github.com/codecheckers/codecheck/issues/73)).
- Added a Zenodo community link to the footer.

### Bug Fixes

- Fixed a grouping error in the venue table.
- Fixed a crash from a missing paper title during CSV generation.
- Fixed icon font, JavaScript, CSS, and logo paths on nested pages.

## codecheck (development version)

### Certificate Page Improvements

- Codechecker names on certificate pages now link to their register page
  rather than their ORCID profile (closes
  [\#141](https://github.com/codecheckers/codecheck/issues/141)).
- Certificate pages now link the venue type and venue name (closes
  [\#142](https://github.com/codecheckers/codecheck/issues/142)).
- Certificate pages now include venue-based breadcrumb navigation.

### Visual Improvements

- ORCID icons now use the official ORCID brand color.
- Updated the Zenodo icon to the official logo.
- Improved icon alignment across register pages.

### Infrastructure Improvements

- Temporary HTML section files are now cleaned up after rendering.
- Register CSS moved out of inline styles into a dedicated stylesheet.
- External libraries (Bootstrap, Font Awesome, Academicons) are now
  managed locally instead of via CDN, with provenance tracking.

### Bug Fixes

- Fixed a rendering error from a missing table details name.
- Fixed broken venue type hyperlinks.

### Venue Configuration and Label Integration

- Venue information now loads from `venues.csv` instead of being
  hardcoded.
- Venue pages now link to their open GitHub issues.
- Breaking change:
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  now requires a `venues_file` parameter.

### GitHub Issue Validation

- Certificates are now validated against their GitHub issue: a missing
  issue fails validation, a closed or unassigned issue raises a warning.

### ORCID Validation Improvements

- ORCID validation now handles authentication failures gracefully, with
  a new `skip_on_auth_error` option for CI and offline use.

### Manifest Rendering Enhancements

- Certificates can now render more file formats in the manifest section,
  including TIF, GIF, EPS, SVG, JSON, TSV, and multi-page PDFs.
- A missing or unsupported manifest file no longer fails the whole
  certificate; it now shows an error message in the PDF instead.

## codecheck 0.22.0

### Certificate Automation and Validation

- Certificate IDs can now be retrieved automatically from the matching
  GitHub issue.
- `codecheck.yml` can now be validated for syntax errors and
  auto-completed with missing fields.
- Paper and author/codechecker metadata can now be validated against
  CrossRef and ORCID records.
- Placeholder certificate IDs and report DOIs are now flagged with a
  visible warning in rendered PDFs.

### Lifecycle Journal Integration

- Article metadata can now be retrieved automatically from Lifecycle
  Journal to populate `codecheck.yml` (closes
  [\#82](https://github.com/codecheckers/codecheck/issues/82)).

### Bug Fixes

- Fixed Zenodo certificate upload failing due to an API signature
  change.
- Fixed ORCID icon links in PDF certificates.
- Fixed handling of NULL/empty fields during certificate rendering.
- Fixed Zenodo alternate identifiers not being set per the curation
  policy.

### Enhancements

- Zenodo certificate upload can now include additional files, including
  the certificate source (`.Rmd`/`.qmd`).
- A new Zenodo record’s DOI is now written back to `codecheck.yml`
  automatically, and the record is submitted to the CODECHECK community.
- Zenodo metadata uploads now comply with the CODECHECK curation policy
  (publisher, resource type, identifiers).
- DOI validation is now platform-agnostic (Zenodo, OSF, ResearchEquals,
  …).

## codecheck 0.21.0

- Added a pkgdown documentation site.
- Fixed a typo in abstract text retrieval.
- Fixed repository URL validation to properly check HTTP responses.

## codecheck 0.20.0

- Renamed fields in register output for consistency.
- Updated footer contact information and removed individual maintainer
  references.

## codecheck 0.19.0

- Fixed namespace issues.
- Added support for specifying a from/to range when rendering the
  register.

## codecheck 0.18.0

- Added validation of the certificate identifier format (`NNNN-NNN`,
  e.g. “2024-001”) in
  [`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md).

## codecheck 0.17.0

- Added support for downloading certificates from the ResearchEquals
  platform.

## codecheck 0.16.0

- Added support for accessing `codecheck.yml` in a subdirectory of a
  GitHub repository via `github::org/repo|subpath`.
- Added a TL;DR section to the README for template usage.

## codecheck 0.15.0

- Improved handling of PDF import in the certificate template.

## codecheck 0.14.0

- Added TU Delft Data Champion Centre (DCC) and eLife as venues; removed
  unused venue entries.
- Fixed Zenodo hyperlinks in register output.
- Hardened handling of missing ORCIDs in the codechecker field.
- Added venue hyperlinks to register pages.
- Fixed a missing codechecks column.

## codecheck 0.12.0

- Added support for retrieving `codecheck.yml` from Zenodo records via
  `zenodo::1234567` and `zenodo-sandbox::1234567`.

## codecheck 0.11.6

- Fixed JSON output including markdown hyperlinks by mistake.

## codecheck 0.11.5

- Fixed imports to reflect API changes in the zen4R package.

## codecheck 0.11.4

- Replaced a custom URL-check helper with
  [`httr::http_error()`](https://httr.r-lib.org/reference/http_error.html),
  improving URL validation.

## codecheck 0.11.3

- Added logging of cache usage for check and render operations.

## codecheck 0.11.2

- Fixed codechecker hyperlink generation when the ORCID ID is missing.

## codecheck 0.11.1

- Fixed certificate pages that have no certificate preview available.

## codecheck 0.11.0

- Added individual certificate HTML pages.
- Added abstract retrieval from CrossRef and OpenAlex.

## codecheck 0.10.1

- Fixed venue type page hyperlinks.

## codecheck 0.10.0

- Fixed URL links in venue and venue type tables.

## codecheck 0.9.0 / 0.8.0

- Replaced the repository column in the register with platform-prefixed
  specifications (GitHub, OSF, GitLab, Zenodo).

## codecheck 0.7.0

- Added Amsterdam UMC as a venue.

## codecheck 0.6.0

- Split the register by type (journal, conference, community,
  institution).
- Added filtered CSV files by venue and codechecker.

## codecheck 0.5.0

- Added support for multiple output formats (HTML, JSON, Markdown).

## codecheck 0.4.0

- Added codechecker-specific register views.

## codecheck 0.3.0

- Added remote configuration retrieval.

## codecheck 0.2.0

- Added register rendering functionality, supporting multiple venues and
  codecheckers.

## codecheck 0.1.0

- Initial release: basic CODECHECK workspace creation, certificate
  generation, and Zenodo integration.

## codecheck 0.0.0.90xx

- Added a `NEWS.md` file to track changes to the package.

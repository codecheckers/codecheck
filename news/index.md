# Changelog

## codecheck 0.27.0

### New Features

- New data model for representing CODECHECK certificates as linked data,
  in the CODECHECK Wikibase and in Wikidata (register#50).
  `R/wikidata.R` holds only the model and its accessors, no HTTP or
  QuickStatements. A certificate carries `P13046` *publication type of
  scholarly work* so it resolves in the query service’s cross-graph
  join, links to the checked paper via `P6977` *review of* rather than
  `P2860`, and gets a venue-derived `P31` (AGILE reproducibility reviews
  are typed separately from CODECHECKs). Only certificates are created
  on Wikidata; papers, people and venues are resolved against existing
  items and otherwise created only in the mirroring CODECHECK Wikibase.
  New
  [`wikidata_model()`](http://codecheck.org.uk/codecheck/reference/wikidata_model.md),
  [`wikidata_entity_kinds()`](http://codecheck.org.uk/codecheck/reference/wikidata_entity_kinds.md),
  [`wikidata_statements()`](http://codecheck.org.uk/codecheck/reference/wikidata_statements.md),
  [`wikidata_properties()`](http://codecheck.org.uk/codecheck/reference/wikidata_properties.md),
  [`wikidata_endpoint()`](http://codecheck.org.uk/codecheck/reference/wikidata_endpoint.md),
  [`wikidata_creates()`](http://codecheck.org.uk/codecheck/reference/wikidata_creates.md),
  [`validate_wikidata_model()`](http://codecheck.org.uk/codecheck/reference/validate_wikidata_model.md),
  [`wikidata_pending()`](http://codecheck.org.uk/codecheck/reference/wikidata_pending.md).

- Register, venue, person, and work tables gain click-to-sort column
  headers (vendored `stupidtable.js`); columns holding a link/title
  rather than a plain value (Report, Work) are excluded. New
  [`add_sortable_th_attributes()`](http://codecheck.org.uk/codecheck/reference/add_sortable_th_attributes.md).

- New `/works/<DOI>/` landing page for a checked paper (register#150):
  lists every certificate that checked it, a metadata panel (DOI,
  OpenAlex, venues, authors linked to their own person page), Schema.org
  (`ScholarlyArticle` + `Review` graph), and an
  `index.json`/`register.json` API queryable by DOI - a paper with no
  DOI has no page. New
  [`add_work_key()`](http://codecheck.org.uk/codecheck/reference/add_work_key.md),
  [`normalize_work_key()`](http://codecheck.org.uk/codecheck/reference/normalize_work_key.md),
  [`get_work_metadata_fields()`](http://codecheck.org.uk/codecheck/reference/get_work_metadata_fields.md),
  [`generate_work_metadata_html()`](http://codecheck.org.uk/codecheck/reference/generate_work_metadata_html.md)/`_yaml()`,
  [`generate_work_schema_org()`](http://codecheck.org.uk/codecheck/reference/generate_work_schema_org.md),
  [`create_all_works_table()`](http://codecheck.org.uk/codecheck/reference/create_all_works_table.md).

- New `/persons/<ORCID>/` landing page (register#123), replacing
  `/codecheckers/`: covers both roles a person can have, showing “Works
  authored” and “Checks conducted” as two separate tables, with role
  counts in `stats.json` and a `Person` + `Review`/`ScholarlyArticle`
  Schema.org graph. Only ORCID-identified people get a page. New
  [`add_person_records()`](http://codecheck.org.uk/codecheck/reference/add_person_records.md),
  [`explode_person_records()`](http://codecheck.org.uk/codecheck/reference/explode_person_records.md),
  [`generate_person_metadata_html()`](http://codecheck.org.uk/codecheck/reference/generate_person_metadata_html.md),
  [`generate_person_schema_org()`](http://codecheck.org.uk/codecheck/reference/generate_person_schema_org.md),
  [`create_all_persons_table()`](http://codecheck.org.uk/codecheck/reference/create_all_persons_table.md).
  A new `docs/404.html`
  ([`generate_404_page()`](http://codecheck.org.uk/codecheck/reference/generate_404_page.md))
  redirects a stray `/codecheckers/<X>/` link to `/persons/<X>/` and,
  for an unmatched `/works/<DOI>`, explains that no CODECHECK has been
  registered for that DOI.

- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)’s
  default `filter_by` is now `c("venues", "works", "persons")` (was
  `c("venues", "codecheckers")`).

- Certificate pages link each ORCID-bearing paper author to their own
  `/persons/<ORCID>/` page (previously only linked if that author was
  also a codechecker) and link the paper title to its `/works/<DOI>/`
  page when it has one.

- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  warns about two certificates that share a paper title but not a
  DOI-normalized work key (a likely same-paper duplicate that would
  otherwise render as two separate `/works/` pages,
  e.g. register#133/#149), and about an ORCID recorded under materially
  different names or a name recorded under different ORCIDs across the
  register. New
  [`check_near_duplicate_works()`](http://codecheck.org.uk/codecheck/reference/check_near_duplicate_works.md),
  [`check_orcid_conflicts()`](http://codecheck.org.uk/codecheck/reference/check_orcid_conflicts.md).

- `register.md` is no longer generated for a person page, since its two
  tables (works authored, checks conducted) can’t be represented as the
  one markdown table every other filter’s `register.md` assumes. New
  `CONFIG$FILTERS_WITHOUT_MD`.

- The “CSV source”/“CSV on GitHub” footer links (formerly “searchable
  CSV”) now show only on the main, unfiltered register page.

- The top navigation menu is now shown on every page, not just overview
  pages; each menu item and the logo gained hover text.

- `.navbar-menu .nav-link` font size reduced from `2rem` to `0.95rem`
  and its breadcrumb counterpart matched to it.

- Added a ResearchEquals collection link to the page footer, next to the
  Zenodo community link.

- Venue landing pages show a metadata panel with website, contact,
  description, identifiers and logo, from new `venues.csv` columns
  (register#84).

- A venue’s `statistics.json` is renamed to `index.json`, since it now
  carries more than statistics (register#183).

- `venues.csv` gained optional `logo_url`, `website_url`, `policy_url`
  and `publisher` columns.

- New statistics dashboard page at `docs/statistics/index.html` with
  charts, a venue grid and a publisher table (addresses register#33,
  register#48). New
  [`render_statistics_page()`](http://codecheck.org.uk/codecheck/reference/render_statistics_page.md).

- Venue type colours are now pinned by name in
  `CONFIG$VENUE_TYPE_COLORS` instead of assigned by the order types
  appear in the data.

- JSON/Markdown export links below register tables are now relative
  rather than absolute `codecheck.org.uk` URLs.

- Venue and codechecker `register.md` exports carry their metadata as
  YAML frontmatter instead of embedded HTML.

- Certificates published on ResearchEquals are now audited against the
  CODECHECK curation policy, including membership in the CODECHECK and
  Reproducible AGILE collections. New
  [`check_researchequals_record()`](http://codecheck.org.uk/codecheck/reference/check_researchequals_record.md)
  and
  [`researchequals_policy_check()`](http://codecheck.org.uk/codecheck/reference/researchequals_policy_check.md).

- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  and
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  gained `check_researchequals_policy` (default `TRUE`), the
  ResearchEquals counterpart of `check_zenodo_policy`.

- A “Go to random certificate” button on the main register page jumps to
  a random certificate instead of the oldest one (register#188).

- Certificate pages now carry Highwire Press citation metadata, so
  Google Scholar can index a certificate and Zotero saves it as a report
  (register#52).

- Certificate pages describe themselves in their OpenGraph metadata
  instead of describing the register as a whole, and gained an
  `og:image` of the certificate’s first page.

- A certificate’s title is now read from the platform it is published on
  rather than constructed as “CODECHECK Certificate \<ID\>”.

- A certificate’s Schema.org JSON-LD gained `publisher`, `inLanguage`,
  the record DOI as `identifier` and the certificate PDF as `encoding`.

- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  and
  [`register_render_cert()`](http://codecheck.org.uk/codecheck/reference/register_render_cert.md)
  gained `prune_unavailable_metadata` (default `FALSE`), controlling
  whether an OpenAlex ID or abstract confirmed unavailable is removed
  from the rendered output.

- Codechecker profiles are now looked up in the institutional and
  Reproducible AGILE codechecker lists as well as the volunteer one, so
  those codecheckers’ pages show an avatar and GitHub link
  (register#215). New
  [`get_institutional_codecheckers_data()`](http://codecheck.org.uk/codecheck/reference/get_institutional_codecheckers_data.md)
  and
  [`get_agile_codecheckers_data()`](http://codecheck.org.uk/codecheck/reference/get_agile_codecheckers_data.md).

- A codechecker’s own page shows a metadata panel with their avatar,
  ORCID, GitHub profile and the venues they contributed checks to
  (register#74, register#189, register#83, register#75).

- A codechecker’s `stats.json` gained a `codechecker` field with their
  name, identifiers and contributed venues (register#78).

- The all-codecheckers table gained a “Check types” column with a
  stacked bar per codechecker, and their own page the same breakdown as
  a donut (register#92, register#207).

### Bug Fixes

- A `codecheck.yml` that cannot be retrieved no longer aborts the whole
  register render: the affected entry is rendered without the metadata
  and a warning names the certificate and the error, instead of the
  render stopping at the first rate limited or unreachable repository.
- [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  rejects an empty register, or a `from`/`to` selection outside it, up
  front with a message saying so, instead of carrying rows of `NA` into
  the enrichment steps and failing later with an unrelated error.
- The download of a `codecheck.yml` from OSF is now retried like the two
  OSF API calls preceding it, so a rejection from OSF’s file server
  (e.g. `Forbidden (HTTP 403)` when the anonymous quota is exhausted) no
  longer ends the render.
- The Zenodo DOI badge in the page footer no longer renders its raw URL
  as visible link text next to the badge image.
- Codechecker and venue pages’ Schema.org `Review` entities no longer
  embed markdown link syntax in `@id`, `url` and `name`.
- Pages without Schema.org metadata of their own no longer emit an empty
  `<script type="application/ld+json">`; they fall back to the generic
  CODECHECK website metadata as intended.
- A certificate’s OpenAlex ID and abstract are now looked up once per
  certificate instead of three times, and a failed lookup no longer
  drops the field.
- [`researchequals_policy_check()`](http://codecheck.org.uk/codecheck/reference/researchequals_policy_check.md)
  reports a missing reference to the checked paper as a warning, not a
  failure: ResearchEquals references cannot be added after publication.
- ResearchEquals certificates whose main file is a document written in
  that platform’s editor are downloaded correctly again (affects
  certificate 2026-014).
- Codechecker pages’ Schema.org JSON-LD includes each certificate’s
  paper title and URL again.
- [`render_cert_htmls()`](http://codecheck.org.uk/codecheck/reference/render_cert_htmls.md)
  no longer emits a spurious `file("") only supports open = "w+"...`
  warning on every render.
- Poppler’s PDF parsing diagnostics are now captured and classified
  instead of printing raw to the console, and are reported under
  parallel rendering too.
- Removed a duplicate definition of
  [`convert_cert_pdf_to_png()`](http://codecheck.org.uk/codecheck/reference/convert_cert_pdf_to_png.md)
  that existed identically in two files.
- The venue table’s `Report` and `Paper Title` column widths were fixed;
  Paper Title was the narrowest column despite carrying the most
  content.
- The `<meta name="generator">` tag now shows just
  `codecheck <version>`, without the git commit hashes.
- A codechecker’s metadata panel no longer disappears entirely for an
  author-only person with no codecheckers.csv entry; it now falls back
  to showing their ORCID.
- Fixed the navbar’s border colour being silently overridden by a later
  shorthand `border-bottom` declaration at equal specificity, so it
  never actually rendered green.
- Breadcrumbs on a venue type overview page (e.g. `/venues/journals/`)
  no longer collapse to a bare, unlinked “Venues”; they now show “Venues
  \> Journals” like every other venue page.
- [`render_register_json()`](http://codecheck.org.uk/codecheck/reference/render_register_json.md)
  and
  [`register_update_stats()`](http://codecheck.org.uk/codecheck/reference/register_update_stats.md)
  no longer duplicate their venue/codechecker/work/person stats-building
  logic, which could otherwise drift between a full render and a
  stats-only update.

## codecheck 0.26.0

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
- Zenodo “concept DOIs” are now rejected in the `report` field of
  `codecheck.yml` (closes codecheckers/codecheck#36).
- A Quarto certificate template (`codecheck.qmd`) is now shipped
  alongside the R Markdown one (closes codecheckers/codecheck#29).
- Licence correction now keeps the licences already on a Zenodo record
  when adding the required CC-BY 4.0.
- Curation findings that need human judgement (e.g. a non-standard title
  or repository) are now surfaced instead of guessed.
- New
  [`curate_register_zenodo_records()`](http://codecheck.org.uk/codecheck/reference/curate_register_zenodo_records.md)
  applies mechanical Zenodo metadata corrections across a whole register
  in one batch.
- [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  gained `creator_overrides` to control how individual creator names are
  split or kept as an organisation.
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

### Bug Fixes

- [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  no longer aborts the whole run when Zenodo rate-limits it.
  [`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  and
  [`is_zenodo_latest_version()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_latest_version.md)
  now query Zenodo’s plain record endpoint directly instead of through
  zen4R’s search-based lookups, which carried a much stricter,
  easily-tripped limit; requests are paced adaptively from Zenodo’s own
  `X-RateLimit-*` response headers rather than a fixed guess, with a
  `cli` message logged whenever a wait is actually applied, and a 429 is
  retried automatically.
- [`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  no longer misreports a rate-limited lookup as a concept DOI.
- [`is_zenodo_latest_version()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_latest_version.md)
  no longer misreports a record’s own latest version as outdated: it
  compared record IDs against a second, search-based lookup that is not
  reliably ordered by version, and could return a stale record even when
  the checked one was in fact current. It now reads the authoritative
  `is_latest` flag already present on the record itself.
- `rprojroot` is now declared as a package dependency, fixing a
  missing-function error on a clean install.
- The ORCID icon on certificate pages is now clickable and links to the
  ORCID profile.
- The ORCID icon in the PDF certificate no longer silently goes missing
  (closes codecheckers/codecheck#37).
- A creator recorded as an organisation is now reported as information,
  not an error, in the Zenodo curation policy check (raised in
  codecheckers/register#205).
- ORCID name checks no longer fail a fresh, unauthenticated workspace.
- A fresh workspace now passes strict CrossRef and ORCID name validation
  out of the box.
- The register CSS is now written to the output directory rather than
  the working directory.
- [`create_codecheck_files()`](http://codecheck.org.uk/codecheck/reference/create_codecheck_files.md)
  now reports the correct target folder (closes
  [\#87](https://github.com/codecheckers/codecheck/issues/87)).
- OSF certificate retrieval now survives an OSF outage instead of
  failing with an unrelated parsing error.
- Rendering no longer rewrites `docs/libs/PROVENANCE.csv` on every run
  when nothing changed.
- A failed library download is no longer stored as if it were the
  library file.
- ResearchEquals certificates can be downloaded again after that
  platform’s API change.
- A register in which no codechecker has an ORCID or GitHub identifier
  now renders correctly.
- Zenodo curation no longer truncates titles that need a human’s review.
- A clear error message is now shown when a Zenodo token may not edit a
  record.
- Codecheckers are now recorded as persons, not organisations, in Zenodo
  metadata.
- Alternate identifiers are no longer silently dropped when uploading
  Zenodo metadata.
- Record titles now match the curation policy (“CODECHECK Certificate
  \<ID\>”).
- A missing or non-DOI paper reference now raises a clear warning.

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

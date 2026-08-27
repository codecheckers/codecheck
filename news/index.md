# Changelog

## codecheck 0.25.0.9012

### New Features

- **[`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now also checks the checked repository itself**:
  [`check_repository_org()`](http://codecheck.org.uk/codecheck/reference/check_repository_org.md)
  fails the entry if the GitHub repository is not under `codecheckers/`
  or the GitLab project not under `cdchck/`, mirroring the same rule
  already enforced for Zenodo records.
  [`check_repository_archived()`](http://codecheck.org.uk/codecheck/reference/check_repository_archived.md)
  warns if the repository is not archived, closing
  codecheckers/codecheck#25.
  [`check_repository_badge()`](http://codecheck.org.uk/codecheck/reference/check_repository_badge.md),
  [`check_repository_license()`](http://codecheck.org.uk/codecheck/reference/check_repository_license.md)
  and the new
  [`check_repository_topic()`](http://codecheck.org.uk/codecheck/reference/check_repository_topic.md)
  report, as information only, a missing CODECHECK badge (closing
  codecheckers/codecheck#75), a missing license, or a missing
  `codecheck` topic tag - none of these are required by the spec, so
  none should stop a check or count as a defect.
  [`check_repository_topic()`](http://codecheck.org.uk/codecheck/reference/check_repository_topic.md)
  closes codecheckers/codecheck#14. New helpers
  [`get_github_repo_metadata()`](http://codecheck.org.uk/codecheck/reference/get_github_repo_metadata.md),
  [`get_github_readme_raw()`](http://codecheck.org.uk/codecheck/reference/get_github_readme_raw.md),
  [`get_gitlab_project_metadata()`](http://codecheck.org.uk/codecheck/reference/get_gitlab_project_metadata.md)
  and
  [`get_gitlab_readme_raw()`](http://codecheck.org.uk/codecheck/reference/get_gitlab_readme_raw.md)
  (`R/configuration.R`) back the GitHub/GitLab lookups; OSF and Zenodo
  repositories are unaffected, as none of these concepts apply there.
- **[`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md)
  now enforces more of the CODECHECK config spec, and
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  catches duplicate certificate IDs**: closing codecheckers/codecheck#9.
  When given a file path, the function now checks that the file is valid
  UTF-8 and that it starts with the YAML document marker `---`, both
  MUST requirements of the [config
  spec](https://codecheck.org.uk/spec/config/1.0/) that were previously
  unchecked (raw bytes are needed for both, so they only run for a file
  path, not for an already-parsed list). It also now requires at least
  one `codechecker` entry, matching the spec’s “at least one child
  element”. Separately,
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now rejects the whole register up front if any `Certificate` value is
  duplicated across rows, rather than only ever comparing one row’s
  certificate against its own repository’s `codecheck.yml`.
- **[`zenodo_policy_check()`](http://codecheck.org.uk/codecheck/reference/zenodo_policy_check.md)
  gains three checks from codecheckers/codecheck#20**: the deposit title
  must contain the certificate ID (e.g. “2026-023”), not just the fixed
  text “CODECHECK Certificate”; a certificate PDF present under a name
  other than `codecheck.pdf` now warns instead of silently passing; and
  a new `record` argument (the full record from
  [`get_zenodo_record_metadata()`](http://codecheck.org.uk/codecheck/reference/get_zenodo_record_metadata.md))
  enables a new “community” check confirming the deposit is a member of
  the Zenodo `codecheck` community - skipped when `record` is not
  supplied, since community membership is not part of `metadata`.
  [`check_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/check_zenodo_record.md)
  and
  [`check_register_zenodo_policy()`](http://codecheck.org.uk/codecheck/reference/check_register_zenodo_policy.md)
  now pass the full record through.

### Bug Fixes

- **[`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  no longer misreports an old record as a concept DOI when the Zenodo
  API is rate-limited**: on an HTTP error (e.g. 429 “Too Many
  Requests”), zen4R’s `getRecordByConceptId()` returns a
  `ZenodoException` object rather than `NULL`, so `!is.null(record)`
  read this as “yes, a concept DOI was found” and
  [`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md)
  failed with the misleading message “… is a Zenodo concept DOI”. The
  function now detects a `ZenodoException` and raises a clear error
  about the failed request instead.
  [`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  and
  [`get_zenodo_record_metadata()`](http://codecheck.org.uk/codecheck/reference/get_zenodo_record_metadata.md)
  also now send the `ZENODO_TOKEN` environment variable as a bearer
  token when set, since an authenticated request gets a much higher
  Zenodo rate limit than an anonymous one - both previously ignored it
  even when set, which is what made the rate limit easy to hit during
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md).
- **`rprojroot` declared as a package dependency**: `codecheck.Rmd` and
  `codecheck.qmd`’s setup chunk calls `find_root()` from `rprojroot`,
  but the package was never listed in `DESCRIPTION`, so a clean install
  (e.g. `r-lib/actions/setup-r-dependencies` on CI) never installed it;
  [`require("rprojroot")`](https://rprojroot.r-lib.org/) then failed
  silently and `find_root()` errored with “could not find function”.
  This broke every test that renders the certificate template
  (`test_manifest_file_rendering.R`, `test_render_qmd_workspace.R`).

## codecheck 0.25.0.9011

### New Features

- **Zenodo “concept DOIs” are now rejected in the `report` field of
  `codecheck.yml`**: Zenodo assigns every deposit both a
  version-specific DOI and a “concept DOI” that always resolves to the
  latest version (see [Zenodo
  versioning](https://zenodo.org/help/versioning)); using the latter in
  a certificate’s `report` field means the certificate no longer points
  at an immutable record. New
  [`is_zenodo_concept_doi()`](http://codecheck.org.uk/codecheck/reference/is_zenodo_concept_doi.md)
  (`R/zenodo.R`) detects this by comparing the DOI’s record ID against
  the concept ID reported by the Zenodo API.
  [`validate_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/validate_codecheck_yml.md)
  now fails strict validation on a concept DOI, and
  [`validate_certificate_for_rendering()`](http://codecheck.org.uk/codecheck/reference/validate_certificate_for_rendering.md)
  (used by both `codecheck.Rmd` and `codecheck.qmd`) gains a
  `check_concept_doi` argument (default `TRUE`) that shows the same
  warning box at render time, degrading gracefully if the Zenodo API is
  unreachable. Closes codecheckers/codecheck#36
- **A Quarto certificate template is now shipped alongside the R
  Markdown one**: `codecheck.qmd` (`inst/extdata/templates/codecheck/`)
  mirrors `codecheck.Rmd` - same helper calls, same PDF appearance via
  `codecheck-preamble.sty` and the `xelatex` engine - and adds demo
  (non-executed) R/Python/Julia chunks plus links to the Quarto docs,
  closing codecheckers/codecheck#29.
  [`create_codecheck_files()`](http://codecheck.org.uk/codecheck/reference/create_codecheck_files.md)
  and `copy_codecheck_report_template()` gain a
  `template = c("all", "rmd", "qmd")` argument (default `"all"`) to pick
  which source(s) to copy into a new workspace. Since having both files
  around makes it unclear which is the canonical certificate source,
  both templates now warn at render time if their sibling is also
  present, the shipped `Makefile` refuses to build if both exist, and
  [`zenodo_policy_check()`](http://codecheck.org.uk/codecheck/reference/zenodo_policy_check.md)’s
  “machine-readable certificate” check now fails a deposit that contains
  both a `.Rmd` and a `.qmd` source.

### Bug Fixes

- **ORCID icon on certificate pages is now clickable and links to the
  ORCID profile**: the HTML certificate page showed no ORCID icon at
  all - only the name itself was a plain text link.
  [`add_paper_details_md()`](http://codecheck.org.uk/codecheck/reference/add_paper_details_md.md)
  and
  [`add_codecheck_details_md()`](http://codecheck.org.uk/codecheck/reference/add_codecheck_details_md.md)
  (`R/utils_render_cert_md.R`) now also render the academicons ORCID
  glyph as a link to `https://orcid.org/<id>` next to each name with an
  ORCID ID, matching the icon already used on codechecker profile pages.

- **ORCID icon in the PDF certificate no longer silently goes missing**:
  `codecheck-preamble.sty`’s `\orcidicon` used the `academicons`
  package’s `\aiOrcid`, which selects the icon font by OS-level family
  name (via fontspec’s `\newfontfamily`). On a system where the font
  isn’t registered with the OS font system (fontconfig) - which is not
  guaranteed by a plain TeX Live/TinyTeX install - this silently falls
  back to a legacy 8-bit TFM with no ORCID glyph, so the icon vanished
  with no compile error. `\orcidicon` now loads `academicons.ttf`
  directly by filename via `\newfontface`, resolved through TeX’s own
  search path, so it no longer depends on OS font registration. Closes
  codecheckers/codecheck#37

- **An organisational creator is reported as information, not as an
  error**:
  [`zenodo_policy_check()`](http://codecheck.org.uk/codecheck/reference/zenodo_policy_check.md)
  failed a record whenever any creator was recorded as an organisation,
  but that can be correct - a workshop’s participants recorded as one
  entry is a genuine group, not a person mistakenly recorded as one, and
  record metadata alone cannot tell the two apart. The “creators” check
  now reports this as a new `"info"` status rather than `"fail"`, so it
  is surfaced to a human to judge instead of asserted as a defect, and
  never makes a record non-compliant.
  [`check_register_zenodo_policy()`](http://codecheck.org.uk/codecheck/reference/check_register_zenodo_policy.md)
  gains an `n_info` column, and
  [`report_zenodo_policy_findings()`](http://codecheck.org.uk/codecheck/reference/report_zenodo_policy_findings.md)
  and
  [`check_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/check_zenodo_record.md)
  display info-level findings with an info icon during rendering. Raised
  in codecheckers/register#205

## codecheck 0.25.0.9010

### Bug Fixes

- **ORCID name checks no longer fail a fresh, unauthenticated
  workspace**: `codecheck.Rmd`’s `validate_crossref` chunk called
  `validate_contents_references(strict = TRUE)` with ORCID’s
  `skip_on_auth_error` left off, so `make all` hard-failed on a
  brand-new certificate unless the codechecker already had working ORCID
  authentication - and the error’s own advice to run
  [`rorcid::orcid_auth()`](https://rdrr.io/pkg/rorcid/man/orcid_auth.html)
  could never fix it for a co-author’s or codechecker’s ORCID, since a
  personal token only authorizes reading the authenticated user’s own
  record. `get_orcid_name()` now falls back to the public,
  unauthenticated ORCID API
  ([`get_orcid_name_public()`](http://codecheck.org.uk/codecheck/reference/get_orcid_name_public.md))
  whenever the authenticated lookup fails, which succeeds for any record
  with a public name and needs no token at all; the template also
  enables `skip_on_auth_error = TRUE` by default so rendering still
  completes even when both lookups fail (e.g. offline)
- **A fresh workspace now passes strict CrossRef and name validation out
  of the box**: the shipped example `codecheck.yml`’s `reference` field
  held a non-DOI semanticscholar PDF link, which CrossRef validation
  always fetched and always got a 404 for; it is now the same `FIXME`
  placeholder style already used elsewhere in the template, which the
  existing placeholder-skip check recognizes. Separately, both the
  CrossRef and ORCID name-matching checks split names on whitespace and
  treated any 2+ character token as significant, so a middle initial
  like “S.” (2 characters, period included) could never match a
  spelled-out middle name like “Samuel” in the authoritative record -
  exactly what the example author “Leslie S. Smith” hit against ORCID’s
  “Leslie Samuel Smith”. Both comparisons now strip periods before
  splitting, so initials are correctly reduced to a single,
  insignificant character
- **`test_workspace_creation.R` no longer expects a shipped `outputs/`
  directory**: the test asserted
  [`create_codecheck_files()`](http://codecheck.org.uk/codecheck/reference/create_codecheck_files.md)
  produces a `codecheck/outputs` folder, but that folder is empty in the
  template source, which git never tracks and which `R CMD build`
  explicitly strips from the package tarball (“Removed empty directory
  …”) - so the assertion only ever passed by accident, when a stray
  local copy happened to exist. `codecheck.Rmd` already creates
  `outputs/` on demand during rendering (see the `manifest` chunk), so
  the test now only checks for the files that are actually shipped

### New Features

- **Licence correction keeps the licences already on a record**: the
  curation policy requires the certificate to be CC-BY 4.0, but a
  deposit may hold code, data or a source archive under other terms
  alongside it.
  [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  adds CC-BY 4.0 through the new `license` field when it is missing and
  writes the full rights list, leaving every other entry in place -
  stripping one would overrule the depositor’’’s deliberate choice for
  those files.
  [`zenodo_policy_check()`](http://codecheck.org.uk/codecheck/reference/zenodo_policy_check.md)
  accordingly passes any record containing CC-BY 4.0, whatever else is
  listed, and reports the others as covering further artefacts

## codecheck 0.25.0.9009

### Bug Fixes

- **The register CSS is written to the output directory, not to the
  working directory**:
  [`copy_register_css()`](http://codecheck.org.uk/codecheck/reference/copy_register_css.md)
  defaulted to a hardcoded `docs/assets` relative to the working
  directory and ignored where the libraries were being installed, so
  rendering with a `libs_dir` outside the current directory scattered
  `codecheck-register.css` into whatever directory the render happened
  to start from. The assets directory is now derived from the libraries
  directory through the new
  [`register_assets_dir()`](http://codecheck.org.uk/codecheck/reference/register_assets_dir.md),
  which is what the two call sites in
  [`setup_external_libraries()`](http://codecheck.org.uk/codecheck/reference/setup_external_libraries.md)
  pass

## codecheck 0.25.0.9008

### Bug Fixes

- **[`create_codecheck_files()`](http://codecheck.org.uk/codecheck/reference/create_codecheck_files.md)
  reports the right folder**: the confirmation message said “Created
  CODECHECK certificate files at .” instead of naming the `codecheck/`
  subfolder the files were actually copied into, and separately
  `list.files("codecheck")` ignored the `target` argument entirely. Both
  messages now use `cli` alerts (matching the rest of the package) and
  correctly reference `<target>/codecheck/` (closes
  [\#87](https://github.com/codecheckers/codecheck/issues/87))

## codecheck 0.25.0.9007

### Bug Fixes

- **OSF retrieval survives an OSF outage**: `osfr` does its own HTTP and
  parses every response as JSON, so an OSF error page arrived as
  “lexical error: invalid char in json text” instead of a status code,
  and
  [`codecheck_GET_retry()`](http://codecheck.org.uk/codecheck/reference/codecheck_GET_retry.md)
  never saw it.
  [`get_codecheck_yml_osf()`](http://codecheck.org.uk/codecheck/reference/get_codecheck_yml_osf.md)
  retries both `osfr` calls with the same policy used for the requests
  the package makes itself, and reports a clear message when they keep
  failing

### Internal

- **One flaky remote call no longer costs the whole test suite**: a
  failed `expect_silent(x <- ...)` leaves `x` unassigned, so the next
  line referring to `x` aborted the file with “object not found” and R
  halted the run, discarding every test after it. The integration tests
  in `test_codecheck_yml_retrieval.R` and `test_lifecycle_journal.R`
  declare their variables first, so an upstream hiccup costs one failed
  assertion
- **Remote links are asserted by shape**:
  [`get_cert_link()`](http://codecheck.org.uk/codecheck/reference/get_cert_link.md)
  returns a ResearchEquals `/api/files/<key>` URL whose key, like the
  version id it comes from, changes with every new deposit, so
  `test_cert_link.R` matches the shape rather than the identifier of the
  day

## codecheck 0.25.0.9006

### Bug Fixes

- **Rendering no longer rewrites `docs/libs/PROVENANCE.csv` on every
  run**:
  [`setup_external_libraries()`](http://codecheck.org.uk/codecheck/reference/setup_external_libraries.md)
  wrote the provenance file and the libraries README unconditionally,
  with `date_configured = Sys.Date()`, so every render dirtied two
  tracked files even though all libraries were already present and
  nothing was downloaded. The function now checks whether the local
  copies are current - all expected files present and of a plausible
  size, and `PROVENANCE.csv` recording exactly the specified libraries
  and versions - and returns early without touching either file. A
  partial update keeps the recorded date of the libraries it did not
  download, so `date_configured` says when a library was actually
  fetched
- **A failed library download is no longer stored as a library file**:
  the response body was written to the destination before the status
  code was checked, so an HTTP error page landed in, say,
  `bootstrap.min.css`; the
  [`file.exists()`](https://rdrr.io/r/base/files.html) guard then
  skipped that file on every later run and the broken copy stayed
  forever.
  [`download_library_file()`](http://codecheck.org.uk/codecheck/reference/download_library_file.md)
  downloads to a temporary file and moves it into place only on HTTP 200
  with a plausible size, and files below that size are re-downloaded

### Internal

- **One specification for the external libraries**:
  [`external_library_specs()`](http://codecheck.org.uk/codecheck/reference/external_library_specs.md)
  is now the single source of truth, including the font files that were
  hardcoded in `download_font_awesome_fonts()` and
  `download_academicons_fonts()` (both replaced by the spec-driven
  [`download_library_fonts()`](http://codecheck.org.uk/codecheck/reference/download_library_fonts.md)).
  [`libs_are_current()`](http://codecheck.org.uk/codecheck/reference/libs_are_current.md)
  and the download loop derive their expectations from it, so a version
  bump in the specification is enough to force a refresh
- **Tests for the external libraries**: new
  `inst/tinytest/test_external_libs.R` covers the currency check, the
  preserved provenance, and discarded failed downloads offline via
  `with_mocked_codecheck()`, and keeps exactly one real download as an
  integration test that skips when there is no network

## codecheck 0.25.0.9005

### Bug Fixes

- **ResearchEquals certificates can be downloaded again**:
  ResearchEquals replaced its `modules` API with `outputs` and
  `versions`, so `/api/modules/main/<DOI suffix>` - the endpoint
  [`get_researchequals_cert_link()`](http://codecheck.org.uk/codecheck/reference/get_researchequals_cert_link.md)
  built - now answers 404 for every certificate. A DOI resolves to a
  version page, whose id gives the deposited file through
  `/api/versions/<id>` and `/api/files/<key>`; the resolver follows that
  chain and warns when a version carries no file or is not a PDF.
  `CONFIG$CERT_LINKS$researchequals_api` is the apex host, the `www.`
  one only added a redirect
- **A register in which no codechecker has an identifier renders**:
  codecheckers without ORCID and GitHub username are recorded under the
  literal identifier `"NA"`, which
  [`read.csv()`](https://rdrr.io/r/utils/read.table.html) reads back as
  a missing value - and as a logical column when it is the only
  identifier in the register, making
  [`create_filtered_reg_csvs()`](http://codecheck.org.uk/codecheck/reference/create_filtered_reg_csvs.md)
  fail in [`strsplit()`](https://rdrr.io/r/base/strsplit.html) with
  “non-character argument”. `render_table_codecheckers()` failed right
  after it, because `recode()` errors when both identifier dictionaries
  are empty

### Internal

- **Shared test mocks**: new `inst/tinytest/mocks.R` provides
  `with_mocked_codecheck()`, which swaps functions in the package
  namespace and restores them afterwards, along with a fake
  [`codecheck_GET()`](http://codecheck.org.uk/codecheck/reference/codecheck_GET.md),
  a `codecheck.yml` fixture reader and a
  [`get_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/get_codecheck_yml.md)
  that serves it. Tests can state the property they exercise instead of
  depending on what a record on a remote archive happens to contain, and
  a slow or failing archive can no longer abort a run.
  `test_register_edge_cases.R` uses them; its missing-identifier warning
  is now asserted on
  [`add_codechecker()`](http://codecheck.org.uk/codecheck/reference/add_codechecker.md),
  which raises it, because
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  muffles every warning and re-reports it as a `cli` alert

## codecheck 0.25.0.9004

### Bug Fixes

- **Curation no longer truncates titles routed to a human**: the apply
  path read its change set with `$`, which partial-matches on R lists,
  so `changes$title` matched `changes$title_manual` and would have
  overwritten a title carrying extra descriptive text with the bare
  `CODECHECK Certificate <ID>`. The same applies to the repository
  relation. All reads in the apply path are now exact (`[["..."]]`),
  with regression tests
- **Clear message when a Zenodo token may not edit a record**:
  `zen4R::editRecord()` returns a non-record instead of stopping when
  the API answers “Permission denied”, so curating a record deposited by
  another user failed with the unrelated “attempt to apply
  non-function”. The result is now checked and reported as what it is

### New Features

- **Findings that need judgement are surfaced, not guessed**:
  [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  no longer proposes a value where the target does not follow
  mechanically. A title carrying text beyond
  `CODECHECK Certificate <ID>` and a repository outside
  `codecheckers/`/`cdchck` are reported for a human instead, and a
  record with only such findings is never opened for editing

## codecheck 0.25.0.9003

### New Features

- **Batch curation of a register’s Zenodo records**: new
  [`curate_register_zenodo_records()`](http://codecheck.org.uk/codecheck/reference/curate_register_zenodo_records.md)
  applies the mechanical corrections across a whole register, and
  [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  gained a `fields` argument selecting which classes of correction to
  consider. Beyond the title it now also corrects publisher, language,
  resource type and the relation to the checked repository. Creator
  names are excluded from batch runs because splitting a group entry
  such as “Delft 2024-05 participants” into given and family name would
  be wrong. The register project wraps this as
  `make zenodo_curate_all [APPLY=1]`
- **Creator handling can be steered per record**:
  [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  gained `creator_overrides`, keyed by the creator name as recorded.
  `list(organizational = TRUE)` keeps a genuine group entry (e.g. “Delft
  2024-05 participants”) as an organisation, and
  `list(given = "Gabriella", family = "Low Chew Tung")` gives an
  explicit split where the last-token heuristic of
  [`split_person_name()`](http://codecheck.org.uk/codecheck/reference/split_person_name.md)
  would misname a person with a compound family name

## codecheck 0.25.0.9002

### Bug Fixes

- **Codecheckers are recorded as persons on Zenodo**:
  [`upload_zenodo_metadata()`](http://codecheck.org.uk/codecheck/reference/upload_zenodo_metadata.md)
  passed only a full `name` to `zen4R::addCreator()`, which makes Zenodo
  store the codechecker as an *organisation* rather than a person. The
  name is now split into given and family name via the new
  [`split_person_name()`](http://codecheck.org.uk/codecheck/reference/split_person_name.md)
  helper, and any affiliation from `codecheck.yml` is passed along.
  Names that cannot be split (a single token, e.g. a group name) still
  deposit as before, but now emit a warning
- **Alternate identifiers are no longer silently dropped**:
  [`upload_zenodo_metadata()`](http://codecheck.org.uk/codecheck/reference/upload_zenodo_metadata.md)
  wrote the certificate identifiers to `metadata$alternate_identifiers`,
  a legacy field name that the InvenioRDM record model Zenodo uses today
  discards on deposit. The identifiers now go to `metadata$identifiers`,
  so the `cdchck.science/register/certs/<CERT ID>` identifiers required
  by the [community curation
  policy](https://zenodo.org/communities/codecheck/curation-policy)
  actually reach the record
- **Record titles match the curation policy**: deposits are titled
  “CODECHECK Certificate ” instead of “CODECHECK certificate ”
- **Missing paper DOI is loud**: a `paper$reference` that is not a DOI,
  or missing entirely, now raises a warning instead of an easily-missed
  message, because it means the required “reviews” relation to the
  checked paper cannot be created

### New Features

- **Curation policy check during rendering**:
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  and
  [`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
  now audit every Zenodo-hosted certificate against the CODECHECK
  community curation policy and report the findings as a `cli` section
  with per-status icons (✖ required item missing, ! recommendation
  unmet, ℹ record unreachable), followed by a tally. Non-compliance
  never fails a render, and neither does an outage or an unexpected
  error in the check itself. Record metadata is cached via
  [`cached_lookup()`](http://codecheck.org.uk/codecheck/reference/cached_lookup.md),
  so only a cold render pays for the extra requests; pass
  `check_zenodo_policy = FALSE` (or `make render CHECK_ZENODO=0` in the
  register project) to skip them. New functions
  [`check_register_zenodo_policy()`](http://codecheck.org.uk/codecheck/reference/check_register_zenodo_policy.md),
  [`report_zenodo_policy_findings()`](http://codecheck.org.uk/codecheck/reference/report_zenodo_policy_findings.md)
  and
  [`clear_zenodo_policy_cache()`](http://codecheck.org.uk/codecheck/reference/clear_zenodo_policy_cache.md),
  the latter also called by
  [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  so a freshly curated record is not reported from its pre-curation
  cache entry
- **Curation policy audit for published records**: new
  [`zenodo_policy_check()`](http://codecheck.org.uk/codecheck/reference/zenodo_policy_check.md)
  evaluates record metadata against the CODECHECK community curation
  policy and returns a data frame of pass/warn/fail per requirement.
  [`check_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/check_zenodo_record.md)
  fetches a published record and prints the audit,
  [`curate_zenodo_record()`](http://codecheck.org.uk/codecheck/reference/curate_zenodo_record.md)
  proposes and (with `dry_run = FALSE`) applies the corrections, and
  [`resolve_zenodo_record_id()`](http://codecheck.org.uk/codecheck/reference/resolve_zenodo_record_id.md)
  resolves a certificate ID via `register.csv` and the repository’s
  `codecheck.yml` to a Zenodo record. The register project wraps these
  as `make zenodo_check CERT_ID=…` and `make zenodo_curate CERT_ID=…`

## codecheck 0.25.0

### New Features

- **Full metadata register export**: New `register-full.json` and
  `register-full.csv` files are now generated during rendering,
  containing all fields from each certificate’s `codecheck.yml` — paper
  authors with ORCIDs, codecheckers with ORCIDs, summary, source, report
  link, and paper reference. The JSON format preserves nested arrays for
  authors and codecheckers, while the CSV uses semicolon-separated
  values for multi-value fields. Both files are sorted by certificate ID
  for consistent diffs (codecheckers/register#57)
- **Single certificate rendering**: New exported function
  [`register_render_cert()`](http://codecheck.org.uk/codecheck/reference/register_render_cert.md)
  renders a single certificate’s HTML page and JSON metadata by
  certificate ID, without modifying index or list pages. Accepts a
  certificate ID (e.g., `"2024-017"`) and optionally downloads and
  converts the certificate PDF. Useful for updating individual
  certificates after metadata or PDF changes without a full register
  re-render. The register project includes a corresponding
  `make cert CERT_ID=2024-017` target for convenient command-line usage
  (codecheckers/codecheck#84)
- **Redirect page for /certs/ directory**: Visiting `/register/certs/`
  without a certificate ID now redirects to the main register page
  instead of showing a 404 error (codecheckers/register#166)
- **Rich logging with cli**: Register rendering now uses the `cli`
  package for structured, colored output with progress bars, section
  headers, and semantic alerts (success/info/warning/danger). Pandoc
  verbose output from
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
  is suppressed by default; pass `verbose = TRUE` to
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  to enable detailed debugging output
- **Warnings captured and shown as log entries**: All R warnings emitted
  during
  [`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
  are now captured and displayed as structured `cli` warning entries at
  the end of rendering, deduplicated with occurrence counts. This
  replaces R’s default “There were N warnings (use warnings() to see
  them)” prompt which was impossible to act on after the R session ended

### Bug Fixes

- **Fixed stray libs/ folders from parallel rendering**: Parallel
  certificate rendering (`mclapply` forking) could leave behind stray
  `libs/` directories in certificate folders due to pandoc temp file
  conflicts between forked processes sharing the same `/tmp` directory.
  A post-render cleanup sweep now automatically removes these stray
  folders after parallel rendering completes
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

# CLAUDE.md

## Overview

The `codecheck` R package assists in conducting
[CODECHECKs](https://codecheck.org.uk/) - independent verification of
computational research. Two main subsystems:

1.  **Workspace creation** (`R/codecheck.R`, `R/configuration.R`,
    `R/validation.R`, `R/zenodo.R`) - Create CODECHECK workspaces,
    validate `codecheck.yml`, upload to Zenodo
2.  **Register management** (`R/register.R`, `R/utils_*.R`) - Render the
    [CODECHECK Register](https://codecheck.org.uk/register/) website
    from `register.csv`

## Committing

**Never commit. Stage changes with `git add` and propose a commit
message; the user commits.** This holds even in auto-accept mode and
even when the change is trivial or the message was agreed beforehand.
The same applies to pushing and to anything that publishes.

## Testing

**CRITICAL: ALWAYS use `tinytest::build_install_test(".")` for
testing.**

DO NOT use `tinytest::test_all(".")` - it causes “could not find
function” errors because the package isn’t properly loaded. Tests are in
`inst/tinytest/`.

For interactive development: `devtools::install()` then
[`library(codecheck)`](http://codecheck.org.uk/codecheck/).

### Fast iteration loop

`build_install_test(".")` builds a tarball and installs with docs and
byte-compilation, which takes minutes. When iterating on a single test
file, install and run the file separately instead - the install takes
about 5 seconds:

``` sh
R CMD INSTALL --no-docs --no-byte-compile --no-staged-install .
R -q -e 'library(codecheck); setwd("inst/tinytest"); tinytest::run_test_file("test_<name>.R")'
```

`setwd("inst/tinytest")` matters: test files `source("mocks.R")` and
read fixtures relative to their own directory. Skipping docs means
`man/` is not rebuilt, so run `devtools::document()` and a full
`build_install_test(".")` before proposing the change.

Test runtime is dominated by installation, not by the tests: the full
edge-case file runs in under 5 seconds.

### When to run the full suite

After a large or multi-file change, run the focused test files touched
by the change (as above), then offer to run the full
`build_install_test(".")` suite - but let the user decide when to
actually run it; do not run it unprompted just because a change was
“large”.

**Exception: always run the full suite, not just an offer, before/after
any non-dev version bump**
(i.e. `usethis::use_version("patch"|"minor"|"major")`, or any manual
`DESCRIPTION` edit that drops the `.9000`-style dev suffix). A version
bump is a release signal, and the full suite is the only thing that has
caught cross-file regressions like stale template fixtures or build-tool
quirks (e.g. `R CMD build` silently stripping empty directories) that
focused tests can’t see.

## Changelog

Always update `NEWS.md` when making changes. Follow the existing
`# codecheck X.Y.Z` header format.

**Match the length and level of detail of the existing entries.** An
entry is one bullet of one sentence, typically 10-25 words: what changed
from the user’s point of view, the issue reference in parentheses
(`closes codecheckers/codecheck#N`, `register#N`), and at most a short
“New `some_function()`” clause for a new public function. Not the root
cause, not the call sites, not the reasoning behind the design - that
belongs in code comments, the commit message and the issue. One change
that touches several user-visible things is several bullets, not one
long one. Fixes go under `## Bug Fixes`, not `## New Features`.

A longer entry is allowed where it genuinely earns it - a subtle bug
whose *symptom* needs describing so somebody recognises it, or a change
whose behaviour is surprising without a caveat. Propose it and say why
rather than writing it silently, and keep it to two or three sentences.

## Design Principles

### Data vs. Presentation Separation

R functions should prepare data, NOT generate HTML. HTML structure
belongs in template files (`inst/extdata/templates/`) using
Whisker/Mustache placeholders. R populates templates via
`whisker::render()`.

### Version Management

Semantic versioning. Use
`usethis::use_version("patch"|"minor"|"major"|"dev")` to bump. If that
fails (uncommitted changes), edit `DESCRIPTION` and `NEWS.md` manually.

`use_version()` only touches `DESCRIPTION` and adds an empty `NEWS.md`
heading above the accumulated dev-cycle entries; it does not consolidate
them under the release heading, regenerate `man/`, or touch
`CITATION.cff`. A release therefore also needs:

- Merge the dev-cycle `# codecheck X.Y.Z.9NNN` sections `use_version()`
  leaves below the new heading into that heading’s own
  `## New Features`/`## Bug Fixes` (etc.) lists, then delete the
  now-empty dev headings.
- Align the merged entries’ style, length, content and links with the
  historic entries below them: one or two sentences per bullet (per
  <https://style.tidyverse.org/news.html>, referenced in
  `CONTRIBUTING.md`), not a multi-paragraph writeup accumulated over a
  dev cycle - trim implementation narrative down to the user-facing
  change, and match how existing entries cite an issue
  (`(closes codecheckers/register#N)` / `(register#N)`) rather than a
  bare `#N` or no reference at all.
- Run `devtools::document()` so `man/` reflects the current code
  (roxygen doesn’t stamp the package version into `.Rd` files, but a
  stale `man/` from skipped `--no-docs` installs during iteration should
  not ship in a release).
- Update the hardcoded `version:` and `date-released:` fields in
  `CITATION.cff` - nothing else touches this file, so it silently
  drifted for several releases (last correct at 0.21.0) before being
  caught at 0.26.0.

## Architecture

### Register Rendering Pipeline

Entry point:
[`register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
in `R/register.R`. Flow:

1.  Load `register.csv` + `config.R` (CONFIG environment)
2.  [`preprocess_register()`](http://codecheck.org.uk/codecheck/reference/preprocess_register.md) -
    enrich data from remote `codecheck.yml` files
3.  [`render_cert_htmls()`](http://codecheck.org.uk/codecheck/reference/render_cert_htmls.md) -
    generate individual certificate HTML pages (supports
    `parallel=TRUE`)
4.  [`create_filtered_reg_csvs()`](http://codecheck.org.uk/codecheck/reference/create_filtered_reg_csvs.md) -
    CSV files per venue/codechecker
5.  [`create_register_files()`](http://codecheck.org.uk/codecheck/reference/create_register_files.md) -
    register tables in HTML/MD/JSON
6.  [`create_non_register_files()`](http://codecheck.org.uk/codecheck/reference/create_non_register_files.md) -
    venue and codechecker summary pages

Output goes to `docs/` with structure:
`docs/{index,certs/,venues/,codecheckers/}`.

### Configuration (`inst/extdata/config.R`)

The `CONFIG` environment holds all settings: column definitions, URL
patterns, venue name mappings, template paths, display settings. Read
the file directly for details.

### Templates (`inst/extdata/templates/`)

- `cert/` - Certificate page templates (base + no-cert variant)
- `reg_tables/` - Register table templates
- `non_reg_tables/` - Venue/codechecker list templates
- `general/` - Shared HTML headers/footers/navigation

Uses Pandoc/rmarkdown for Markdown→HTML, Whisker for HTML partials.

### Remote Configuration (`R/configuration.R`)

[`get_codecheck_yml()`](http://codecheck.org.uk/codecheck/reference/get_codecheck_yml.md)
fetches from multiple platforms via
[`parse_repository_spec()`](http://codecheck.org.uk/codecheck/reference/parse_repository_spec.md): -
`github::org/repo`, `osf::ABC12`, `gitlab::project/repo`,
`zenodo::1234567`

Results are cached via `R.cache`. Clear with
[`register_clear_cache()`](http://codecheck.org.uk/codecheck/reference/register_clear_cache.md).

### Relationship with ../register Repository

The `../register` repo contains `register.csv` (data) and `docs/`
(output, deployed via GitHub Pages). Workflow: edit CSV → `make render`
calls
[`codecheck::register_render()`](http://codecheck.org.uk/codecheck/reference/register_render.md)
→ output to `docs/`.

### Key Data Structures

**codecheck.yml**: `certificate`, `paper` (title, authors with ORCID),
`codechecker`, `manifest`, `report` (Zenodo DOI), `repository`,
`check_time`. Template at `inst/extdata/templates/codecheck.yml`.

**register.csv**: Certificate, Repository (platform-prefixed), Type,
Venue, Issue, Report, Check date.

## Implementation Notes

- **HTML relative paths**: Internal links use relative paths for
  localhost dev; JSON/CSV keep absolute URLs. Depth calculated per
  output directory level.
- **Shared libs**:
  [`edit_html_lib_paths()`](http://codecheck.org.uk/codecheck/reference/edit_html_lib_paths.md)
  rewrites paths to shared `docs/libs/` folder
- **Codechecker column**: Contains R lists (multiple codecheckers per
  check); unnested for CSV/grouping
- **Abstracts**: Fetched from CrossRef, then OpenAlex as fallback
- **JS libraries**: Stored locally in `inst/extdata/js/` (no CDN).
  Citation.js needs both `citation.min.js` + `citation-wrapper.js`
- **Parallel rendering**: `register_render(parallel=TRUE)` uses
  `mclapply()`/`parLapply()`. ~6x speedup on 8 cores
- **Log format**: Certificate operations prefix with cert ID for
  parallel log readability
- **Rate limiting**: Set `GITHUB_PAT` env var; Zenodo has 1s delay
  between requests
- **Venue names**: Short names in CSV mapped to display names via
  `CONFIG$DICT_VENUE_NAMES`

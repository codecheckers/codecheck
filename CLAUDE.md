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

## Testing

**CRITICAL: ALWAYS use `tinytest::build_install_test(".")` for
testing.**

DO NOT use `tinytest::test_all(".")` - it causes “could not find
function” errors because the package isn’t properly loaded. Tests are in
`inst/tinytest/`.

For interactive development: `devtools::install()` then
[`library(codecheck)`](http://codecheck.org.uk/codecheck/).

## Changelog

Always update `NEWS.md` when making changes. Follow the existing
`# codecheck X.Y.Z` header format.

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

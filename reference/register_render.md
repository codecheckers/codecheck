# Function for rendering the register into different view

NOTE: You should put a GitHub API token in the environment variable
\`GITHUB_PAT\` to fix rate limits. Acquire one at see
https://github.com/settings/tokens.

## Usage

``` r
register_render(
  register = read.csv("register.csv", as.is = TRUE, comment.char = "#"),
  filter_by = c("venues", "codecheckers"),
  outputs = c("html", "md", "json"),
  config = c(system.file("extdata", "config.R", package = "codecheck")),
  venues_file = "venues.csv",
  codecheck_repo_path = NULL,
  from = 1,
  to = nrow(register),
  parallel = FALSE,
  ncores = NULL,
  verbose = FALSE,
  check_zenodo_policy = TRUE,
  check_researchequals_policy = TRUE,
  prune_unreferenced_libs = TRUE,
  prune_unavailable_metadata = FALSE
)
```

## Arguments

- register:

  A \`data.frame\` with all required information for the register's view

- filter_by:

  The filter or list o filters (if applicable)

- outputs:

  The output formats to create

- config:

  A list of configuration files to be sourced at the beginning of the
  rending process

- venues_file:

  Path to the venues.csv file containing venue names and labels

- codecheck_repo_path:

  Optional path to the codecheck package repository for build metadata
  (default: NULL)

- from:

  The first register entry to check

- to:

  The last register entry to check

- parallel:

  Logical; if TRUE, renders certificates in parallel using multiple
  cores. Defaults to FALSE.

- ncores:

  Integer; number of CPU cores to use for parallel rendering. If NULL,
  automatically detects available cores minus 1. Defaults to NULL.

- verbose:

  Logical; if TRUE, shows detailed output including pandoc commands from
  rmarkdown::render(). Defaults to FALSE.

- check_zenodo_policy:

  Logical; if TRUE (the default), audits all Zenodo-hosted certificates
  against the CODECHECK community curation policy after rendering and
  reports the findings on the console. Never fails a render. Results are
  cached, so only a cold render pays for the extra requests; set to
  FALSE to skip them entirely.

- check_researchequals_policy:

  Logical; if TRUE (the default), audits all certificates published on
  ResearchEquals against the CODECHECK curation policy after rendering,
  including membership in the CODECHECK collection and, for AGILEGIS
  certificates, in the Reproducible AGILE collection, and reports the
  findings on the console. Never fails a render. Results are cached like
  the Zenodo ones; set to FALSE to skip them entirely.

- prune_unreferenced_libs:

  Logical; if TRUE (the default), removes directories under
  \`docs/libs\` that no rendered HTML file references any more (see
  \[prune_libs()\] and codecheckers/codecheck#89) once rendering
  finishes. Only actually runs after a complete, unfiltered render
  (\`from\`/\`to\` covering the whole register) with no certificate
  failures; otherwise the step is skipped with a message, since a
  partial render can leave HTML that still references a directory this
  would delete.

- prune_unavailable_metadata:

  Logical; if TRUE, a certificate's OpenAlex ID or abstract that this
  render's live lookup conclusively confirms is no longer available (as
  opposed to a lookup that simply failed - network error, rate limit) is
  actually removed from the rendered output. Defaults to FALSE: such a
  confirmed absence is more often a query problem than a real removal
  upstream, so by default the previously rendered value is kept, and a
  lookup failure never removes anything regardless of this flag. See
  \[resolve_external_field()\].

## Value

A \`data.frame\` of the register enriched with information from the
configuration files of respective CODECHECKs from the online
repositories

## Details

\- \`.html\` - \`.md“

## Author

Daniel Nuest

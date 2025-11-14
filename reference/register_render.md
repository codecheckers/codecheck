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
  ncores = NULL
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

## Value

A \`data.frame\` of the register enriched with information from the
configuration files of respective CODECHECKs from the online
repositories

## Details

\- \`.html\` - \`.md“

## Author

Daniel Nüst

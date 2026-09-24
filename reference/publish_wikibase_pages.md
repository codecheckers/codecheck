# Rewrite the generated pages on the CODECHECK Wikibase

Each page is otherwise written only as a side effect of the step it
belongs to - the bootstrap, the load, the preview of the Wikidata
export - and says what was true when that step last ran. This rebuilds
them all from the register and the instance as they are now, so the
pages can be brought up to date without repeating any of those steps; in
the register, \`make wikibase\`.

## Usage

``` r
publish_wikibase_pages(
  dir = "../register",
  pages = NULL,
  dry_run = TRUE,
  log_file = NULL,
  method = c("search", "sparql")
)
```

## Arguments

- dir:

  the register repository

- pages:

  the pages to write, names of the package's page registry (\`"main"\`,
  \`"about"\`, \`"copyrights"\`, \`"copyright_redirect"\`,
  \`"data_model"\`, \`"example_queries"\`, \`"certificates"\`,
  \`"wikidata_export"\`); \`NULL\`, the default, for all of them

- dry_run:

  if \`TRUE\` (the default) report which pages would change without
  writing; a real run needs \`WIKIBASE_USER\` and \`WIKIBASE_TOKEN\`

- log_file:

  the edit log, or \`NULL\` for the \`codecheck.wikibase_log\` option;
  the Wikidata export page lists the batches it records as run

- method:

  how to resolve against Wikidata, see \[preview_wikidata_export()\]

## Value

a \`data.frame\` with one row per page and its status, invisibly

## Details

Reads the register's rendered \`docs/register.json\` (render first) and
\`register.csv\`, the instance, and - for the Wikidata export page -
Wikidata itself. Writes only pages, never items, and only the pages
whose content has changed.

## Examples

``` r
if (FALSE) { # \dontrun{
publish_wikibase_pages("../register")                   # what would change
publish_wikibase_pages("../register", dry_run = FALSE)  # write it
} # }
```

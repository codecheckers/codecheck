# Write generated pages onto the instance

The one place a page is written, whichever function generated it. A page
whose content has not changed is left alone, see
\[wikibase_page_unchanged()\].

## Usage

``` r
write_wikibase_pages(session, texts, summary, log_file = NULL, dry_run = FALSE)
```

## Arguments

- session:

  a session from \[wikibase_session()\]; \`NULL\` with \`dry_run\`

- texts:

  a named list, \[WIKIBASE_PAGES\] key to the page's wikitext

- summary:

  the edit summary

- log_file:

  the edit log, or \`NULL\` for the \`codecheck.wikibase_log\` option

- dry_run:

  if \`TRUE\` compare with the instance and write nothing

## Value

a \`data.frame\` with the \`page\` key, its \`title\` and its
\`status\`: \`"written"\`, \`"unchanged"\`, \`"would create"\` or
\`"would update"\`, invisibly

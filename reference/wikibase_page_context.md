# What the page generators need, fetched only when a page asks for it

Each value is a promise: publishing only the Main Page reads nothing,
while the Wikidata export page resolves every certificate against
Wikidata. A caller that already holds a value - the bootstrap its plan,
the load what it wrote - assigns it over the promise.

## Usage

``` r
wikibase_page_context(
  dir = "../register",
  session = NULL,
  log_file = NULL,
  method = "search"
)
```

## Arguments

- dir:

  the register repository

- session:

  a session from \[wikibase_session()\], or \`NULL\` to read anonymously

- log_file:

  the edit log, or \`NULL\` for the \`codecheck.wikibase_log\` option

- method:

  how to resolve against Wikidata, see \[preview_wikidata_export()\]

## Value

an environment

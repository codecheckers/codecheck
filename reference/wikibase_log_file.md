# Where the edit log is written

\`NULL\` - the default - means no log is kept, which is what an
exploratory \`dry_run\` wants. Set \`options(codecheck.wikibase_log =
"wikibase-log.csv")\`, or pass a path, to keep one.

## Usage

``` r
wikibase_log_file(file = NULL)
```

## Arguments

- file:

  an explicit path, or \`NULL\` to fall back to the option

## Value

the path, or \`NULL\`

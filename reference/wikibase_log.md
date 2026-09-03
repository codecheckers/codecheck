# Append entries to the edit log

Appends rather than rewrites, and never fails the write it is recording:
a log that cannot be written is worth a warning, not a lost edit.

## Usage

``` r
wikibase_log(..., file = NULL)
```

## Arguments

- ...:

  columns of one entry, named as in \[WIKIBASE_LOG_COLUMNS\]; \`time\`
  is filled in

- file:

  the log path, or \`NULL\` to keep no log

## Value

the entry, invisibly

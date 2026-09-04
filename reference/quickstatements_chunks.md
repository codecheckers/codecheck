# Split QuickStatements commands into batches of whole items

Splits only at \`CREATE\`, never inside an item: the statements after a
\`CREATE\` address it as \`LAST\`, so a chunk boundary in the middle of
one would attach them to whatever the previous chunk created last.

## Usage

``` r
quickstatements_chunks(commands, size = QUICKSTATEMENTS_EDIT_LIMIT)
```

## Arguments

- commands:

  the QuickStatements v1 commands, one per element

- size:

  how many items per chunk

## Value

a list of command vectors; a single element if no split is needed

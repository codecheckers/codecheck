# The QuickStatements commands for one entity

The QuickStatements commands for one entity

## Usage

``` r
quickstatements_for_entity(kind, row, qid = NULL, resolve = NULL)
```

## Arguments

- kind:

  an entity kind

- row:

  the register row

- qid:

  the existing item to add to, or \`NULL\` to create one

- resolve:

  a function \`(entity_kind, key) -\> QID\`

## Value

a character vector of commands, tab separated

# Write a QuickStatements batch out for somebody to paste

The Wikidata half of the export is a person copying commands into
QuickStatements under their own account, so what the code can do is
prepare exactly what they paste, keep a copy of it, and record that it
was prepared. The file is the evidence of what was submitted; without
it, a batch that half-succeeded is unreconstructable, since the register
will have moved on.

## Usage

``` r
quickstatements_write(
  commands,
  batch,
  dir = ".",
  target = c("wikidata", "wikibase"),
  file = NULL,
  chunk_size = QUICKSTATEMENTS_EDIT_LIMIT
)
```

## Arguments

- commands:

  the QuickStatements v1 commands, one per element

- batch:

  a name for this batch, used for the file name and in the log

- dir:

  where to write the \`.qs\` file

- target:

  \`"wikidata"\` or \`"wikibase"\`, which instance it is meant for

- file:

  the log path, or \`NULL\` to use the option

- chunk_size:

  how many items one file may create before it is split; see
  \[QUICKSTATEMENTS_EDIT_LIMIT\]

## Value

the paths of the written files, invisibly

## Details

A batch that would create more items than Wikidata lets an account edit
in a minute is written as several numbered files, each its own batch in
the log, to be pasted one after another. Splitting beforehand is the
difference between a run that stops cleanly at a file boundary and one
that fails part-way through with 42 items missing and no record of
which.

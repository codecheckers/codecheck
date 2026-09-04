# Retire a batch file that has been pasted

A \`.qs\` file whose batch has been run is the duplicate-paste hazard
itself: QuickStatements' \`CREATE\` has no idempotency, so a second
paste makes a second item for everything in it. Renaming rather than
deleting keeps the commands around - which ones failed is a question
worth being able to answer - while taking away the name that invites a
paste.

## Usage

``` r
quickstatements_retire(path)
```

## Arguments

- path:

  the file recorded when the batch was prepared

## Value

the new path, or \`NA\` if there was nothing to retire

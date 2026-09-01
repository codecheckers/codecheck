# All codecheckers from all three lists, volunteers first

Somebody may be in more than one list (a volunteer who later also
codechecks for their institution, say), so the lookups below take the
\*first\* match: \`codecheckers.csv\` is the richer record and wins, and
the order of the other two only decides which \`source\` label a person
in both gets.

## Usage

``` r
all_codechecker_records()
```

## Value

A data frame with the columns of \[CODECHECKER_LIST_COLUMNS\] plus
\`source\`, one of \`volunteer\`, \`institutional\` or \`agile\`.

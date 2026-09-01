# Rename the "Paper Title" column to "Work" for display

The underlying data column stays "Paper Title" everywhere it is read
internally (title extraction, work-key lookups, etc.) - only the header
text a reader actually sees in a rendered table is renamed, to align
with "work" as used everywhere else on the platform (the \`/works/\`
section, the \`Work\` column in
\`CONFIG\$NON_REG_TABLE_COL_NAMES\[\["works"\]\]\`, the JSON \`work\`
field). Renaming the data column itself would touch every function that
reads it; this only ever runs on a copy about to be handed straight to
\`kable()\`.

## Usage

``` r
rename_paper_title_column_for_display(register_table)
```

## Arguments

- register_table:

  A register table, possibly with a "Paper Title" column.

## Value

The same table, with that column renamed to "Work" if present.

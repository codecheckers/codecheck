# Explode a register table's \`Person\` list column into one row per record

Turns each certificate's list of \`orcid, name, role\` records (see
\[add_person_records()\]) into its own row, replacing the \`Person\`
list column with a plain \`Person\` character column (the ORCID,
matching \`CONFIG\$FILTER_COLUMN_NAMES\[\["persons"\]\]\`, so the caller
can \`group_by()\` it directly) plus a \`Role\` column
("author"/"codechecker"). A certificate with no ORCID-identified person
at all contributes no rows.

## Usage

``` r
explode_person_records(register_table)
```

## Arguments

- register_table:

  A register table with a \`Person\` list column.

## Value

The exploded register table - one row per person-record, \`Person\` now
the person's ORCID and \`Role\` the record's role. Zero rows (same
columns) if no certificate has an ORCID-identified person.

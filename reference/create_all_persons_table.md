# Create the "all persons" overview table (docs/persons/index.html)

Mirrors \[create_all_codecheckers_table()\], but counts both roles:
works authored and checks conducted, per ORCID. Only ORCID-identified
persons are ever present in \`register_table\$Person\` (see
\[add_person_records()\]), so no "without ORCID" row is needed here the
way the old codechecker table had one (#123 explicitly rules out
name-matching for people without one).

## Usage

``` r
create_all_persons_table(register_table)
```

## Arguments

- register_table:

  The register table, with a \`Person\` list column.

## Value

A list with a single element, the persons table.

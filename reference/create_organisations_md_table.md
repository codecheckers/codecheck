# Build the temp.md content for an organisation page

The organisation analogue of \[create_persons_md_table()\]: the same two
sections, works authored and checks conducted, but every row also names
the person the organisation is on that certificate through - an
organisation is never on a certificate in its own right (register#53).

## Usage

``` r
create_organisations_md_table(register_table, table_details)
```

## Arguments

- register_table:

  The organisation's exploded, per-person-per-role rows (see
  \[explode_organisation_records()\]), already hyperlinked for display.

- table_details:

  List containing details such as the table name.

## Value

The markdown lines (a character vector, one per line).

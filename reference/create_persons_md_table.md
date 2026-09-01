# Build the temp.md content for a person page: two tables, not one

A person page shows works authored and checks conducted as two separate
sections (confirmed against a mockup on real data - see the \#123/#150
implementation plan), so it can't go through \[create_md_table()\],
which assumes a single kable(). This never runs for the public
register.md export (see CONFIG\$FILTERS_WITHOUT_MD) - only for the
HTML-bound temp.md, so there is no column-width override to apply here
(kable's own alignment row is a valid table either way, just not
custom-widened like the others).

## Usage

``` r
create_persons_md_table(register_table, table_details)
```

## Arguments

- register_table:

  The person's exploded, per-role register rows (see
  \[explode_person_records()\]), already hyperlinked for display.

- table_details:

  List containing details such as the table name.

## Value

The markdown lines (a character vector, one per line).

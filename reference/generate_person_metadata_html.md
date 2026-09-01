# Generate the person metadata HTML panel (roles summary + codechecker panel)

A person page (issue codecheckers/register#123) covers two roles at
once - paper author and codechecker - so its panel is a small role-count
summary ("N works authored, M checks conducted") followed by the
existing codechecker panel (\[generate_codechecker_metadata_html()\]:
avatar, ORCID, GitHub, contributed-venues list, donut), built from the
codechecker-role rows only. An author-only person (no codechecker-role
rows) still gets the role summary; the codechecker panel below it
degrades to "" the same way it already does for a codechecker with no
ORCID/GitHub/venues.

## Usage

``` r
generate_person_metadata_html(orcid, register_table, table_details)
```

## Arguments

- orcid:

  The person's ORCID (\`table_details\[\["name"\]\]\` on a person page).

- register_table:

  The person's exploded, per-role register rows (see
  \[explode_person_records()\]), pristine (before display hyperlinks).

- table_details:

  List containing details such as the table name.

## Value

An HTML string (never \`""\` - the role summary always renders).

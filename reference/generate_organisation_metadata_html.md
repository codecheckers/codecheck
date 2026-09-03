# Generate the metadata HTML block for an organisation landing page

The organisation analogue of \[generate_venue_metadata_html()\]: name,
type, location and identifiers from ror.org, a logo from the Wikidata
item the ROR record points at, the register venue that shares the ROR
(if any), and the people this organisation is on the register through.
Fields the ROR record does not carry are omitted rather than shown
empty.

## Usage

``` r
generate_organisation_metadata_html(ror, register_table)
```

## Arguments

- ror:

  The organisation's ROR id (\`table_details\[\["name"\]\]\` on an
  organisation page).

- register_table:

  The organisation's exploded, per-person-per-role rows (see
  \[explode_organisation_records()\]), pristine (before display
  hyperlinks).

## Value

An HTML string.

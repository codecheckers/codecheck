# The organisations a person is on the register through

Rendered under the role summary on a person page: the organisations
their ORCID profile identified with a ROR when they authored or checked
the works in the register (see \[add_organisation_records()\]), each
linked to its own page. Empty - not an empty list, no markup at all -
for the majority of people who have no ROR-identified affiliation on
record (register#53).

## Usage

``` r
person_organisations_html(orcid)
```

## Arguments

- orcid:

  The person's ORCID.

## Value

An HTML string, or \`""\`.

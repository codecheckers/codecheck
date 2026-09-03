# Create one entity on the CODECHECK Wikibase

Create one entity on the CODECHECK Wikibase

## Usage

``` r
create_wikibase_entity(session, row, mapping_property)
```

## Arguments

- session:

  a session from \[wikibase_session()\]

- row:

  one row of the plan from \[plan_wikibase_entities()\]

- mapping_property:

  the local id of the mapping property, or \`NA\` when creating the
  mapping property itself

## Value

the new entity's local id

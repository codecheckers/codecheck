# Fill in the local ids of the entities a plan finds present

Fill in the local ids of the entities a plan finds present

## Usage

``` r
wikibase_plan_local_ids(plan, existing)
```

## Arguments

- plan:

  a plan from \[plan_wikibase_entities()\]

- existing:

  the instance's entities, from \[wikibase_mapping()\]

## Value

the plan with a \`local_id\` column, \`NA\` for what is still to create

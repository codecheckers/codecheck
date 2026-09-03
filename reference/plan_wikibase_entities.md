# Plan the entities the CODECHECK Wikibase needs

The pure half of \[bootstrap_wikibase()\]: given what the instance
already holds, work out what is missing. Separated so the decision can
be tested without touching the network, and so a dry run and a real run
cannot disagree about what would be created.

## Usage

``` r
plan_wikibase_entities(existing)
```

## Arguments

- existing:

  a mapping as returned by \[wikibase_mapping()\]

## Value

a \`data.frame\` with columns \`kind\` (\`"property"\` or \`"item"\`),
\`wikidata_id\`, \`label\`, \`description\`, \`datatype\`, \`role\` and
\`action\` (\`"create"\` or \`"present"\`)

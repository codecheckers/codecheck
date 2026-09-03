# Refuse rows whose identity key is not unique

Every entity is found again by the identifier the model resolves it on,
so two rows sharing one are not two entities: they are one, written
twice, and the second overwrites the first. The register can contain
this - certificates 2025-009 and 2025-010 name the same OSF record - and
it renders there without trouble, so the export cannot assume it away.
It is caught here rather than silently reduced to one item, on Wikidata
most of all, where the loser is gone without a trace.

## Usage

``` r
check_export_keys(rows, kinds = names(rows))
```

## Arguments

- rows:

  the tables from \[wikibase_export_rows()\]

- kinds:

  which of them to check

## Value

\`TRUE\` invisibly, or an error naming the collisions

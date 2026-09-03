# Collect the Wikidata items the register's pages can link to

Fills \`CONFIG\$WIKIDATA_IDS\` with one lookup per entity kind, each a
named character vector from the identifier the page is keyed on to a
QID.

## Usage

``` r
load_wikidata_ids(register_table, persons_file = NULL)
```

## Arguments

- register_table:

  the preprocessed register table

- persons_file:

  path to the register's record of people on Wikidata, a CSV with
  \`orcid\` and \`wikidata\` columns, read before resolving and written
  back after. \`NULL\` to neither read nor write it.

## Value

the lookups, invisibly

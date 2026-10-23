# Who created an item, and whether it was the CODECHECK export

Who created an item, and whether it was the CODECHECK export

## Usage

``` r
wikidata_item_origin(comment, batch_ids = character(0))
```

## Arguments

- comment:

  the edit comment of the item's first revision

- batch_ids:

  the batches the edit log records, see \[wikidata_logged_batch_ids()\]

## Value

\`"codecheck export"\` for a create from a logged batch,
\`"quickstatements"\` for one from a batch the log does not know, and
\`"other"\` for anything else

# The QuickStatements batches the edit log records as run on Wikidata

A create names its batch in the edit comment:
\`#temporary_batch\_\<id\>\` for a run in the foreground,
\`batch/\<id\>\` for one in the background. The log records the same ids
in the URLs of the batches it was told were submitted.

## Usage

``` r
wikidata_logged_batch_ids(log_file = NULL)
```

## Arguments

- log_file:

  the edit log

## Value

the batch ids, as character

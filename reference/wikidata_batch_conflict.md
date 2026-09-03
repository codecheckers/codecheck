# Whether a batch of creates would repeat one that was already submitted

QuickStatements' \`CREATE\` has no idempotency and Wikidata will not
stop a second paste: running the works batch twice makes a second item
for every work, which then has to be merged by hand. The dangerous
moment is narrow and predictable - a batch has been submitted, and the
entities it created still do not resolve, either because the index has
not caught up or because the batch failed. Either way the answer is to
wait and look, not to paste again.

## Usage

``` r
wikidata_batch_conflict(kind, creates, log_file = NULL)
```

## Arguments

- kind:

  the entity kind the batch is for

- creates:

  how many entities the new batch would create

- log_file:

  the edit log to consult

## Value

the time of the last submission that looks unaccounted for, or \`NA\`

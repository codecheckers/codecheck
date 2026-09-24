# The wiki page showing the state of the Wikidata export

The Wikibase mirror is where this work can be looked at by somebody who
does not run R, so the export's state belongs there too: which
certificates and checked works have items on Wikidata, which are still
to be created, the commands for those, and the batches that have already
run. The page says which of those stages the export is at, so that it
stays true after the batches have been pasted rather than describing the
export as it was before.

## Usage

``` r
wikidata_preview_wikitext(
  preview,
  certificates,
  batches,
  submitted = NULL,
  register_qids = character(0),
  generated_at = Sys.time()
)
```

## Arguments

- preview:

  the table \[wikidata_export_plan()\] built

- certificates:

  the certificate rows, one table row each

- batches:

  the QuickStatements batches, as attached to the preview

- submitted:

  the batches recorded as run, see \[wikidata_submitted_batches()\]

- register_qids:

  the certificates' items as \`register.csv\` records them, see
  \[read_register_wikidata()\]; empty to leave the column out

- generated_at:

  the timestamp to stamp the page with

## Value

the page's wikitext

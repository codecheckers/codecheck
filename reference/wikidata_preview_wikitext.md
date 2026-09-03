# The wiki page showing what the Wikidata export would do

The Wikibase mirror is where this work can be looked at before any of it
reaches Wikidata, so the preview belongs there too: which works already
have items, which would be created, and the commands themselves, in the
two batches they have to run in.

## Usage

``` r
wikidata_preview_wikitext(
  preview,
  certificates,
  batches,
  generated_at = Sys.time()
)
```

## Arguments

- preview:

  the table \[preview_wikidata_export()\] built

- certificates:

  the certificate rows, for titles and links

- batches:

  the QuickStatements batches, as attached to the preview

- generated_at:

  the timestamp to stamp the page with

## Value

the page's wikitext

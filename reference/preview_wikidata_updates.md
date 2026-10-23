# Preview the additions to items already on Wikidata

The second set of QuickStatements next to \[preview_wikidata_export()\]:
that one creates the items that are missing, this one adds to the items
that exist every statement of the model they do not carry - a statement
the model gained after the item was created, or a value the register
learned later. Nothing is sent.

## Usage

``` r
preview_wikidata_updates(
  dir = "../register",
  out_dir = ".",
  log_file = NULL,
  records = NULL,
  method = c("search", "sparql"),
  origin = TRUE
)
```

## Arguments

- dir:

  the register repository to read from

- out_dir:

  where to write the batch and the report

- log_file:

  the edit log, to record the batch in and to recognise the export's own
  items by

- records:

  already-read records, as from \[read_register_records()\]

- method:

  how to resolve against Wikidata, see \[preview_wikidata_export()\]

- origin:

  whether to look up who created each item, one request per item

## Value

the plan, invisibly: one row per statement to add, to remove, or that
differs or is shared, with the item, its origin and creator, the
property, the proposed and the current value, the action and the command

## Details

A statement whose property the item already carries with another value
is a difference, listed in the report but not in the batch: on Wikidata
it would become a second value rather than a correction. Statements the
export wrote itself are the exception: when their only references point
into the register and the model no longer produces their value, the
batch removes them, before it adds anything, so a corrected value takes
the place of the wrong one. One the export wrote together with somebody
else is reported as \`"shared"\` and left alone. See
\[wikidata_missing_statements()\].

Each item is marked with where it came from. \`"codecheck export"\` is
an item a batch in the edit log created, so the additions finish the
export's own work; \`"quickstatements"\` is one created by a batch the
log does not record, and \`"other"\` one somebody created otherwise - by
hand, or by an import of the publisher's metadata. Those are shared
items, and the additions to them are worth a look before they are
pasted.

## Examples

``` r
if (FALSE) { # \dontrun{
preview_wikidata_updates("../register", out_dir = "wikidata",
                         log_file = "wikidata/wikibase-log.csv")
} # }
```

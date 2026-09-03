# Load the register into the CODECHECK Wikibase

The rehearsal the Wikidata batches are worth doing only after: the whole
register, written as items on an instance that can be thrown away and
rebuilt (codecheckers/register#50).

## Usage

``` r
load_wikibase_register(
  dir = "../register",
  dry_run = TRUE,
  log_file = NULL,
  limit = NULL,
  records = NULL
)
```

## Arguments

- dir:

  the register repository to read from

- dry_run:

  if \`TRUE\` (the default) report what would be written

- log_file:

  where to append the edit log, or \`NULL\` for the
  \`codecheck.wikibase_log\` option

- limit:

  process at most this many certificates, for a first rehearsal

- records:

  already-read records, as from \[read_register_records()\]

## Value

a \`data.frame\` of what was written or would be, invisibly, with the
payloads attached as the \`"payloads"\` attribute

## Details

Entities are written in dependency order - people, venues, papers, then
the certificates that refer to them - because a certificate's \`author\`
and \`review of\` statements can only name items that already exist.
Each entity is matched by the identifier the model resolves it on, so a
rerun updates what it wrote last time instead of duplicating it, and an
update replaces the entity's statements rather than adding a second copy
of each.

Dry by default: with \`dry_run = TRUE\` nothing is written and the
payloads are returned for inspection.

## Examples

``` r
if (FALSE) { # \dontrun{
load_wikibase_register("../register")                    # what would happen
load_wikibase_register("../register", dry_run = FALSE)   # do it
} # }
```

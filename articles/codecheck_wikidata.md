# codecheck: Export the register to Wikidata

The register is also published as linked data: one item per certificate,
per checked work, per codechecker and per venue, so that a CODECHECK can
be queried and cited like any other scholarly object. This document is
the procedure for doing that, start to finish. It is written to be
followed literally, by a person or by an AI assistant, and the order of
the steps matters - the last two write to Wikidata, where a mistake is
public and has to be cleaned up by hand.

See
[codecheckers/register#50](https://github.com/codecheckers/register/issues/50)
for the modelling decisions behind all of this.

## The two targets

There are two, and they behave differently.

|  | CODECHECK Wikibase | Wikidata |
|----|----|----|
| Where | <https://codecheck.wikibase.cloud> | <https://www.wikidata.org> |
| Written by | this package, through the API | a person, pasting QuickStatements |
| Holds | everything: certificates, works, people, venues | certificates and the works they check |
| Repeatable | yes, entities are matched and updated | no, `CREATE` always creates |
| Disposable | yes, rebuild it from empty at any time | no |

The Wikibase is a staging instance, and the one rule about it is that
**nothing may live only there**. Everything on it is generated from
`register.csv` and the model in `R/wikidata.R`, so it can be rebuilt
from an empty wiki whenever needed. Do not record anything there that
exists nowhere else.

Wikidata is the opposite: it is permanent, it is edited under a person’s
own account, and QuickStatements has no undo. That is why the Wikibase
load is the rehearsal and comes first.

## Before you start

Install the package and have a rendered register available - the export
reads `docs/register.json` and `docs/certs/*/index.json` from the
register repository, which is offline and takes seconds, rather than
re-resolving everything from the network.

``` r

remotes::install_github("codecheckers/codecheck")
library(codecheck)
```

Writing to the Wikibase needs a bot password from
<https://codecheck.wikibase.cloud/wiki/Special:BotPasswords> with the
“High-volume editing”, “Edit existing pages” and “Create, edit, and move
pages” grants, in two environment variables. The last of these matters
because the bootstrap creates the hosting-policy pages, and creating a
page is a different grant from editing one:

``` sh
WIKIBASE_USER=<account>@<bot name>
WIKIBASE_TOKEN=<the 32-character password>
```

The register’s `.env` is the place for them; its `Makefile` exports them
to the R process. Reading the Wikibase, and all of Wikidata, is
anonymous and needs no credentials.

Two options are worth setting for any real run:

``` r

# an edit log: the only record of what was written, and the only record at all
# of the batches pasted into Wikidata by hand
options(codecheck.wikibase_log = "wikibase-log.csv")

# Wikimedia's User-Agent policy asks for a way to reach whoever runs the client
options(codecheck.contact = "you@example.org")
```

Every step below is a dry run first. The dry run is not a formality - it
is where a missing property or a wrong label shows up, and it costs
nothing.

## Step 1: bootstrap the Wikibase

The instance mints its own property and item numbers, so `P31` there is
not Wikidata’s `P31`. This creates one local property or item per entry
of the model, each carrying a “Wikidata entity” statement naming its
counterpart.

``` r

bootstrap_wikibase()                  # what would be created
bootstrap_wikibase(dry_run = FALSE)   # create it
```

It is idempotent: what already exists is left alone, matched by its
Wikidata id rather than by label, so a partially failed run can simply
be repeated. It also brings a label that has drifted from the model back
in line, and writes the index at [Project:Data
model](https://codecheck.wikibase.cloud/wiki/Project:Data_model). Every
run also writes
[Project:About](https://codecheck.wikibase.cloud/wiki/Project:About) and
[Project:Copyrights](https://codecheck.wikibase.cloud/wiki/Project:Copyrights),
which the [wikibase.cloud hosting
policy](https://www.wikibase.cloud/hosting-policy) requires of every
hosted instance, so that an instance rebuilt from empty comes back
compliant.

Run this again whenever the model gains a property or an item - the load
in the next step refuses to run against an instance that is missing any
of them.

## Step 2: load the register into the Wikibase

``` r

load_wikibase_register("../register")                    # what would happen
load_wikibase_register("../register", limit = 3)         # a small rehearsal
load_wikibase_register("../register", dry_run = FALSE)   # write it
```

Entities are written in dependency order - people, venues, works, then
the certificates that refer to them - because a certificate’s `author`
and `review of` statements can only name items that already exist. Each
entity is matched by the identifier the model resolves it on (report
DOI, paper DOI, ORCID, ISSN), so a rerun updates what it wrote last time
instead of duplicating it. A second run of a complete load therefore
reports every entity as an update and creates nothing.

The dry run returns the payloads it would send, which is the thing to
look at before writing:

``` r

plan <- load_wikibase_register("../register")
payloads <- attr(plan, "payloads")
str(payloads[["certificate:10.5281/ZENODO.3674056"]], max.level = 2)
```

Afterwards the instance holds the register, and
[Project:Certificates](https://codecheck.wikibase.cloud/wiki/Project:Certificates)
lists every certificate item next to its register page.

**Look at the result before going on.** Open a few certificate items and
check that the statements say what they should. This is the rehearsal;
everything after this point is public.

## Step 3: preview the Wikidata export

``` r

preview <- preview_wikidata_export("../register",
                                   out_dir = "wikidata",
                                   publish = TRUE)
```

This writes nothing to Wikidata. It resolves every certificate and
checked work against Wikidata, works out what exists and what would be
created, writes the QuickStatements batches to `wikidata/`, and (with
`publish = TRUE`) puts the whole preview on the Wikibase as
[Project:Wikidata
export](https://codecheck.wikibase.cloud/wiki/Project:Wikidata_export)
so it can be reviewed by somebody who does not run R.

Read the summary it prints. It tells you how many works are already on
Wikidata, how many would be created, and how many certificates cannot
yet state `review of`.

### How existing items are found

By default resolution asks the Action API’s `haswbstatement` search,
which indexes a new item within minutes and sees every item regardless
of which graph it ended up in. The query service is available as a
cross-check:

``` r

preview_wikidata_export("../register", method = "sparql")
```

Expect the two to disagree slightly, and expect the search to find
*more*. The query service is hours behind, and each of its two endpoints
serves only its own graph - a checked work typed as a report rather than
a scholarly article is invisible to the scholarly endpoint even though
the item exists. Resolving by SPARQL alone would create it a second
time.

### Why there are two batches

QuickStatements v1 can only refer to an item it has just created, as
`LAST`. A certificate therefore **cannot** name a work created in the
same batch. So the works batch runs first, and the certificates batch is
generated again afterwards, once the works have QIDs to point at.

Doing it in the other order produces certificates with no link to the
work they review, which is the one statement the whole model exists for.

## Step 4: paste the works batch

1.  Open <https://quickstatements.toolforge.org/> and log in with your
    own Wikidata account.
2.  *New batch* → V1 syntax.
3.  Paste the contents of `wikidata/wikidata-papers.qs`.
4.  *Import*, check the parsed preview QuickStatements shows, then
    *Run*.
5.  Copy the batch URL it gives you.

Watch the first few commands go through before leaving it. If the batch
fails early - a malformed value, a blocked account - stop and fix it
rather than letting it run on.

## Step 5: record that the batch ran

``` r

quickstatements_submitted("wikidata-papers",
                          url = "https://quickstatements.toolforge.org/#/batch/12345",
                          note = "3 commands failed, see batch page")
```

Nothing else records this. The code cannot observe a paste, and a batch
run last week against a register that has since moved on cannot be
reconstructed from anywhere else.

## Step 6: regenerate, and check the gate

``` r

preview <- preview_wikidata_export("../register", out_dir = "wikidata")
```

**The gate:** it must now report that the works are already on Wikidata
and that there are none to create.

If it still reports works to create, the search index has not caught up
yet - usually minutes. Wait and run it again.

You will not silently get a duplicate batch here: when the log says a
batch of this name was submitted and the works still do not resolve, the
file is *not* written and the reason is printed instead.

    ✖ Not writing the paper batch: one was submitted at 2026-09-02T17:04:11+0200,
      and 91 papers still do not resolve.
    ℹ Either the search index has not caught up - wait and run this again - or that
      batch failed, which its QuickStatements page will say.

Find out which of the two it was - the batch page says whether it ran -
before doing anything else. Only then:

``` r

preview_wikidata_export("../register", out_dir = "wikidata", force = TRUE)
```

> **Do not paste the works batch a second time without checking.**
> `CREATE` has no idempotency and nothing on the Wikidata side will stop
> you: pasting it twice creates a second item for every work, and those
> have to be merged by hand afterwards. To check one DOI directly:
> `https://www.wikidata.org/w/index.php?search=haswbstatement:P356=10.1093/GIGASCIENCE/GIAA026`

## Step 7: paste the certificates batch

Same as step 4, with `wikidata/wikidata-certificates.qs`, and then:

``` r

quickstatements_submitted("wikidata-certificates", url = "...")
```

## Step 8: verify

``` r

verify_wikidata_export("../register")
```

This is the step that proves the model’s central decision worked rather
than only sounding right. It asks two different questions of two
different sources: the search index says whether each certificate item
exists at all, and the query service says whether it is *reachable in
the scholarly graph*, where the works it reviews are.

    ℹ 132 of 132 certificates exist on Wikidata
    ℹ 132 visible in the scholarly graph
    ℹ 124 state review of on the work they checked

The returned table has a row per certificate, so a shortfall can be
looked at directly:

``` r

result <- verify_wikidata_export("../register")
subset(result, !in_scholarly_graph | is.na(review_of))
```

Run it a few hours after the batch, not immediately: the query service
updater lags, and the scholarly endpoint is the slower of the two. An
item that exists but is not yet visible is a lag; the same result the
next day is a fault.

**A certificate that exists but is not in the scholarly graph** is
missing its `P13046` statement. An item lands in the scholarly graph if
its direct `P31` is one of the scholarly types, or if it carries any
`P13046` - a certificate is typed `Q116740091` CODECHECK, which is not a
scholarly type, so `P13046` is the only thing putting it there, and
without it the certificate cannot be joined to the work it reviews.

**A certificate that states no `review of`** either checks a work with
no DOI (8 of them), or was created before the works batch ran.

## The edit log

With `options(codecheck.wikibase_log = ...)` set, every write appends a
row: time, target, action, kind, id, label, status, batch, detail. It
covers both halves of the export - the API writes to the Wikibase, and
the QuickStatements batches prepared for and submitted to Wikidata.

``` r

log <- codecheck:::wikibase_log_read("wikibase-log.csv")
subset(log, target == "wikidata")
```

## If something goes wrong

**The load stops with “The instance is missing N properties of the
model”.** The model gained something the instance does not have. Run
`bootstrap_wikibase(dry_run = FALSE)` and load again.

**A write fails with `maxlag`, `ratelimited` or a 503.** It is retried
automatically with a growing pause. If it fails anyway, run the same
command again - both the bootstrap and the load are idempotent, and they
pick up where they stopped.

**The export stops with “Two or more entities share an identifier”.**
Two certificates name the same report DOI, or two works the same paper
DOI. That identifier is what finds an entity again on the next run, so
the export would write one item for both and the second would overwrite
the first - on Wikidata, irrecoverably. The message names the rows; fix
the register
([`register_check()`](http://codecheck.org.uk/codecheck/reference/register_check.md)
warns about this too) or drop the affected rows before exporting.

**A statement is missing from an item.** Almost always the value could
not be resolved: a work without a DOI, a codechecker without an ORCID, a
venue without an ISSN, or an item the model names that does not exist on
the instance yet. Compare against the dry run’s payload for that entity,
which shows exactly which statements were built.

**Duplicate items on Wikidata.** Merge them with the [Merge
gadget](https://www.wikidata.org/wiki/Help:Merge), keeping the lower
QID, and record what happened with
[`quickstatements_submitted()`](http://codecheck.org.uk/codecheck/reference/quickstatements_submitted.md)’s
`note`. Then find out which step was run twice before running anything
again.

**The Wikibase is in a bad state.** It is disposable. Delete what is
there and run steps 1 and 2 again; the register is the authority and
nothing is lost.

## What is deliberately not exported

- **People and venues are never created on Wikidata.** They are resolved
  against items the communities that maintain them own, and mirrored on
  the Wikibase instead.
- **A work with no DOI gets no item**, on either target: it could not be
  found again on the next run, so it would be created afresh every time.
- **A checked work’s publication comes from the work, not from the
  register.** `P1433` published in is resolved by the ISSN in the work’s
  own OpenAlex record, not from the register’s `Venue` column - one
  register venue can span several publications over the years, and a
  conference is not a publication at all. A work whose record names no
  ISSN (a preprint, a report) gets no such statement. The Wikibase
  additionally holds an item for every publication the works name, since
  `venues.csv` covers only the venues that commission checks; on
  Wikidata those publications are resolved, never created.
- **Statements on items that already exist are not overwritten.** A
  certificate or work Wikidata already holds keeps the label,
  description and statements somebody else chose.

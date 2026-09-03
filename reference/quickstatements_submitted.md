# Record that a QuickStatements batch was actually submitted

The one thing the code cannot observe, and the one thing worth knowing
later: that a prepared batch was pasted, by whom it was run and where
its result can be seen. QuickStatements gives every run a batch URL;
that is what belongs here.

## Usage

``` r
quickstatements_submitted(
  batch,
  url = NA_character_,
  note = NA_character_,
  file = NULL
)
```

## Arguments

- batch:

  the batch name given to \[quickstatements_write()\]

- url:

  the QuickStatements batch URL, if there is one

- note:

  anything worth recording, e.g. which commands failed

- file:

  the log path, or \`NULL\` to use the option

## Value

the log entry, invisibly

## Examples

``` r
if (FALSE) { # \dontrun{
quickstatements_submitted("certificates-2026-09", url = "https://...batch/12345")
} # }
```

# How many items a batch may create before Wikidata throttles it

Wikidata allows a normal account 90 edits per minute, and
QuickStatements writes one edit per item. A background batch pushes as
fast as the API takes it, so item 91 onwards is rejected - reported,
unhelpfully, as "No success flag set in API result". The default leaves
headroom for whatever else the account is doing in the same minute.

## Usage

``` r
QUICKSTATEMENTS_EDIT_LIMIT
```

## Format

a single number

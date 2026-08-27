# Function for checking all entries in the register

This functions starts of a \`data.frame\` read from the local register
file.

## Usage

``` r
register_check(
  register = read.csv("register.csv", as.is = TRUE, comment.char = "#"),
  from = nrow(register),
  to = 1,
  check_zenodo_policy = TRUE
)
```

## Arguments

- register:

  A \`data.frame\` with all required information for the register's view

- from:

  The first register entry to check (defaults to the last row, i.e. the
  newest entry)

- to:

  The last register entry to check (defaults to the first row, i.e. the
  oldest entry)

- check_zenodo_policy:

  Logical; if TRUE (the default), also audits the Zenodo records against
  the CODECHECK community curation policy

## Details

\*\*Note\*\*: The validation of \`codecheck.yml\` files happens in
function \`validate_codecheck_yml()\`. Certificate IDs must also be
unique across the whole register; this is checked once up front, over
all rows, before any per-entry checks run.

Also checks the checked repository itself: organisation membership
(\`check_repository_org()\`), archived status
(\`check_repository_archived()\`), CODECHECK badge presence
(\`check_repository_badge()\`), license presence
(\`check_repository_license()\`) and the \`codecheck\` topic tag
(\`check_repository_topic()\`).

By default entries are checked newest-first (\`from\` defaults to the
last row, \`to\` to the first): problems are more likely to appear in
recent checks and certificates than in old, already-vetted ones, so
breaking issues surface earlier in a full-register run (closes \#79).
Pass \`from = 1, to = nrow(register)\` to check oldest-first instead.

## Author

Daniel Nuest

# Check a register's ResearchEquals certificates against the CODECHECK curation policy

Check all ResearchEquals certificates of a register against the curation
policy

## Usage

``` r
check_register_researchequals_policy(
  register_table,
  get_metadata = get_researchequals_version_metadata,
  get_collections = get_researchequals_collections
)
```

## Arguments

- register_table:

  a register \`data.frame\` with the columns \`Certificate\` and
  \`Report\`, and optionally \`Venue\`, without which the venue-specific
  Reproducible AGILE collection is not checked

- get_metadata:

  function of one argument (the version ID) returning the version
  metadata like \[get_researchequals_version_metadata()\]; injectable
  for testing

- get_collections:

  function of no arguments returning the collections a certificate must
  be part of, like \[get_researchequals_collections()\]; injectable for
  testing

## Value

a data.frame with one row per checked certificate and the columns
\`certificate\`, \`version_id\`, \`status\` ("compliant",
"non-compliant" or "unknown"), \`n_fail\`, \`n_warn\`, \`n_info\` and
\`findings\`

## Details

Runs \[researchequals_policy_check()\] over every register entry whose
report is a ResearchEquals DOI. Meant to run at the end of a register
render as a maintainer signal, so it never fails: an unreachable module,
a 404 or a malformed response yields the status "unknown" rather than an
error, and entries whose report is not on ResearchEquals are skipped.

The collections are fetched once for the whole run; one that cannot be
fetched is skipped rather than reported as a failure for every
certificate.

Version metadata is cached via \[cached_lookup()\], which stores
conclusive results only, so an outage is retried on the next render
instead of being frozen into the cache. Clear it with
\[register_clear_cache()\].

## Author

Daniel Nuest

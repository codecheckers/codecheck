# Check a register's Zenodo records against the CODECHECK curation policy

Check all Zenodo-hosted certificates of a register against the curation
policy

## Usage

``` r
check_register_zenodo_policy(
  register_table,
  get_metadata = get_zenodo_record_metadata
)
```

## Arguments

- register_table:

  a register \`data.frame\` with the columns \`Certificate\` and
  \`Report\`

- get_metadata:

  function of one argument (the record ID) returning the record metadata
  like \[get_zenodo_record_metadata()\]; injectable for testing

## Value

a data.frame with one row per checked certificate and the columns
\`certificate\`, \`record_id\`, \`status\` ("compliant", "non-compliant"
or "unknown"), \`n_fail\`, \`n_warn\` and \`findings\`

## Details

Runs \[zenodo_policy_check()\] over every register entry whose report is
a Zenodo DOI. Meant to run at the end of a register render as a
maintainer signal, so it never fails: an unreachable record, a 404 or a
malformed response yields the status "unknown" rather than an error, and
entries whose report is not a Zenodo DOI are skipped.

Record metadata is cached via \[cached_lookup()\], which stores
conclusive results only, so an outage is retried on the next render
instead of being frozen into the cache. Clear it with
\[register_clear_cache()\].

## Author

Daniel Nuest

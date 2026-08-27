# Check whether a report DOI is the latest version of its Zenodo record

Check whether a report DOI points to the latest version of a Zenodo
record

## Usage

``` r
is_zenodo_latest_version(report, sandbox = FALSE, fetch_record = NULL)
```

## Arguments

- report:

  string containing the report DOI or URL on Zenodo.

- sandbox:

  connect with the Zenodo Sandbox instead of the real service

- fetch_record:

  a function \`function(id, sandbox, follow_redirect)\` returning
  \`list(status, body)\` for a Zenodo record lookup, where \`body\`
  carries a \`versions\` list with an \`is_latest\` field matching the
  real Zenodo API (or \`NULL\` on an unrecoverable request failure), for
  injecting a mock in tests. Defaults to \[fetch_zenodo_record()\], a
  direct HTTP call to the production (or sandbox) API.

## Value

\`TRUE\` if \`report\` is the latest version of its Zenodo record, or is
not a matchable/resolvable Zenodo DOI (nothing to compare against).
\`FALSE\` if a more recent version of the record exists.

## Details

A Zenodo deposit can be updated over time by publishing a new version;
each version gets its own version-specific DOI (see
https://zenodo.org/help/versioning). A CODECHECK certificate's
\`report\` field should always point at the version that was actually
checked \*and\* still be the latest version of that deposit: if a newer
version has since been published, the record's metadata is no longer
guaranteed to reflect what the certificate checked, so the certificate
should either be updated to reference a fresh check of the current
version, or the outdated version should be flagged for transparency
rather than silently accepted. This is a separate concern from
\[is_zenodo_concept_doi()\]: a concept DOI is the wrong \*kind\* of
identifier (it is never version-specific), while this function checks
that a correctly version-specific DOI has not since been superseded by a
newer version of the same record.

## Author

Daniel Nuest

# Check whether a report DOI is a Zenodo concept DOI

Check whether a report DOI is a Zenodo "concept DOI"

## Usage

``` r
is_zenodo_concept_doi(report, sandbox = FALSE, fetch_record = NULL)
```

## Arguments

- report:

  \- string containing the report DOI or URL on Zenodo.

- sandbox:

  connect with the Zenodo Sandbox instead of the real service

- fetch_record:

  a function \`function(id, sandbox, follow_redirect)\` returning
  \`list(status, body)\` for a Zenodo record lookup (or \`NULL\` on an
  unrecoverable request failure), for injecting a mock in tests.
  Defaults to \[fetch_zenodo_record()\], a direct HTTP call to the
  production (or sandbox) API.

## Value

\`TRUE\` if \`report\` is a Zenodo concept DOI, \`FALSE\` if it is a
version-specific DOI or not a (matchable) Zenodo DOI at all.

## Details

Zenodo assigns every versioned deposit two DOIs: a version-specific DOI
(which always resolves to that exact version) and a concept DOI (which
always resolves to the \*latest\* version, see
https://zenodo.org/help/versioning). A CODECHECK certificate's
\`report\` field should reference the version-specific DOI so that the
certificate points at an immutable record; this function detects the
mistake of using the concept DOI instead.

## Author

Daniel Nuest

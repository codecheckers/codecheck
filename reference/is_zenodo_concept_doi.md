# Check whether a report DOI is a Zenodo concept DOI

Check whether a report DOI is a Zenodo "concept DOI"

## Usage

``` r
is_zenodo_concept_doi(report, sandbox = FALSE, zenodo = NULL, logger = NULL)
```

## Arguments

- report:

  \- string containing the report DOI or URL on Zenodo.

- sandbox:

  connect with the Zenodo Sandbox instead of the real service

- zenodo:

  An object from zen4R to connect with Zenodo (or a mock with a
  compatible \`getRecordByConceptId()\` method, for testing). Defaults
  to a new \`ZenodoManager\` connected to the production (or sandbox)
  service. When supplied, \`logger\` is ignored - configure logging on
  the object you pass in instead.

- logger:

  zen4R logger level for the default \`ZenodoManager\` created when
  \`zenodo\` is not supplied: \`NULL\` (the default) keeps output to the
  single \`cli\` alert zen4R always prints per request; \`"INFO"\` or
  \`"DEBUG"\` additionally prints zen4R's own \`\[zen4R\]\[...\]\` line
  for every request (connect, fetch, record count, ...), useful when
  diagnosing rate-limiting or unexpected API responses.

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

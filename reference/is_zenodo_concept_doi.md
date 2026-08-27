# Check whether a report DOI is a Zenodo concept DOI

Check whether a report DOI is a Zenodo "concept DOI"

## Usage

``` r
is_zenodo_concept_doi(report, sandbox = FALSE, zenodo = NULL)
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
  service.

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

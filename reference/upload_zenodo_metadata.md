# Upload metadata to Zenodo

Upload codecheck metadata to Zenodo.

## Usage

``` r
upload_zenodo_metadata(
  zenodo,
  myrec,
  metadata = codecheck_metadata(getwd()),
  resource_types = list()
)
```

## Arguments

- zenodo:

  object from zen4R to connect with Zenodo

- myrec:

  a Zenodo record object

- metadata:

  codecheck metadata (list). Defaults to loading from codecheck.yml in
  the current working directory using `codecheck_metadata(getwd())`.

- resource_types:

  named list to override default resource types for related identifiers.
  Supported names: "paper" (default: "publication-article"),
  "repository" (default: auto-detected). Example:
  `list(paper = "publication-preprint")`

## Value

rec – the updated record.

## Details

The contents of codecheck.yml are uploaded to Zenodo using this
function. By default, loads metadata from codecheck.yml in the current
working directory.

This function complies with the CODECHECK Zenodo community curation
policy: https://zenodo.org/communities/codecheck/curation-policy

Requirements: - Description must include the certificate summary -
Publisher must be "CODECHECK Community on Zenodo" - Resource type must
be "publication-report" - Related identifiers for paper (reviews) and
repository (isSupplementedBy) - Alternate identifiers for certificate ID
(URL and Other schemas)

## Author

Stephen Eglen

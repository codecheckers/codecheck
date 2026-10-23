# Whether an OpenAlex record describes the work the register references

OpenAlex merges a preprint into its published version: looking up the
preprint's DOI answers with the journal article's record, so its venue,
ISSN and publication date are the article's, not the preprint's. The
bioRxiv preprint of certificate 2023-011 came back as the PLOS ONE
article, and the export stated that the preprint was published in PLOS
ONE. A Zenodo record found by its version DOI answers with the concept
DOI's record likewise.

## Usage

``` r
openalex_record_is_work(record_doi, paper_reference)
```

## Arguments

- record_doi:

  The DOI of the OpenAlex record

- paper_reference:

  The paper reference from the register

## Value

\`FALSE\` only when both are DOIs and they differ; a record without a
DOI or a reference that is not one cannot be compared, and passes

## Details

The comparison treats \`\_\` and \`/\` alike, because OpenAlex spells
some old DOIs with slashes where CrossRef registered underscores -
2020-002's \`10.1088/0954-898X_3_1_008\` is
\`10.1088/0954-898x/3/1/008\` there.

# Whether an OpenAlex record of another copy is the record of the work too

OpenAlex merges copies of a work into one record, whose DOI is then one
of them: the arXiv preprint of 2025-019 is a location of the record of
its SSRN copy, the version DOI of 2024-016's Zenodo preprint one of the
record of the concept DOI. Such a record is the work's when it lists the
work's DOI as a location and is of the same kind. A preprint merged into
its published article (2023-011, PLOS ONE) is not: the record is the
article's.

## Usage

``` r
openalex_record_is_copy(fields, paper_reference, paper_kind)
```

## Arguments

- fields:

  the value of \[get_openalex_work_fields_cached_result()\]

- paper_reference:

  the paper reference

- paper_kind:

  \`"preprint"\` or \`"article"\`, see \[paper_kind()\]

## Value

\`TRUE\` or \`FALSE\`

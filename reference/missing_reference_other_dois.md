# DOIs of a work's other copies that its references do not name

OpenAlex merges the records of copies of one work - a preprint on two
servers, a preprint and its version of record - and lists each copy's
DOI. A DOI there that is neither the \`paper.reference\` nor in
\`reference-other\` is a candidate for \`reference-other\` (rule
\`CC-MET-010\`). Only a candidate: OpenAlex merges can be wrong, so a
person decides.

## Usage

``` r
missing_reference_other_dois(
  record_dois,
  paper_reference,
  reference_other = character(0)
)
```

## Arguments

- record_dois:

  The DOIs the record lists, see \[openalex_record_dois()\]

- paper_reference:

  The paper reference

- reference_other:

  The \`reference-other\` URLs, possibly empty

## Value

Character vector of the candidate DOIs, as \`https://doi.org/\` URLs in
lower case

## Details

DOIs compare as \[openalex_record_is_work()\] compares them, and a DOI
that differs from a reference only by a trailing version (\`v2\`) is the
same copy.

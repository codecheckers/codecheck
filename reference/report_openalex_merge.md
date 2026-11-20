# Say when OpenAlex has merged a certificate's work into another record

OpenAlex merges records it considers the same work, and the ID of the
record merged away then redirects to the one it was merged into. The
render keeps the ID this run found, which is the current one; this only
makes the change visible, because the record behind it can describe
another copy of the work (2025-019: the arXiv preprint merged into the
SSRN copy, whose DOI is the record's) and so change the work's
publication, and the certificate's \`reference-other\` may want the
other copy's DOI (see \[suggest_reference_other()\]).

## Usage

``` r
report_openalex_merge(cert_id, previous, current)
```

## Arguments

- cert_id:

  The certificate identifier

- previous:

  The OpenAlex ID of the previous rendering, or \`NULL\`/\`NA\`

- current:

  The OpenAlex ID this render resolved, or \`NA\`

## Value

\`"merged"\`, \`"changed"\` or \`NA\` (no change to report), invisibly

## Details

Costs one cached request, and only for a certificate whose ID changed.

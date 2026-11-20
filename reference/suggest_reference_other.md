# Report a work's other copies as possible \`reference-other\` entries

The render's side of rule \`CC-MET-010\`, which reports the same in
\[validate_codecheck_yml_rules()\]. Nothing is written: the message
names the certificate and gives the YAML to add to its
\`codecheck.yml\`.

## Usage

``` r
suggest_reference_other(
  cert_id,
  record_dois,
  paper_reference,
  reference_other = character(0)
)
```

## Arguments

- cert_id:

  The certificate identifier

- record_dois:

  The DOIs the record lists, see \[openalex_record_dois()\]

- paper_reference:

  The paper reference

- reference_other:

  The \`reference-other\` URLs, possibly empty

## Value

The candidate DOIs, invisibly

# Signposting links for an organisation page

The ROR is the organisation's persistent identifier, so it is what
\`cite-as\` names - the analogue of the ORCID on a person page.

## Usage

``` r
generate_organisation_signposting(ror, has_jsonld = FALSE)
```

## Arguments

- ror:

  The organisation's ROR id.

- has_jsonld:

  Whether an \`index.jsonld\` was written next to the page.

## Value

The \`\<link\>\` elements as an HTML string.

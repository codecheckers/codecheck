# Signposting links for a person page

\`ProfilePage\` is Schema.org's type for exactly this page, and an ORCID
is a persistent identifier for the person the page is about, so a person
page can carry a \`cite-as\` as well. No \`author\`: the person authors
the checks listed on the page, not the page.

## Usage

``` r
generate_person_signposting(orcid, has_jsonld = FALSE)
```

## Arguments

- orcid:

  The person's ORCID

- has_jsonld:

  Whether \`index.jsonld\` was written next to the page

## Value

HTML string of \`\<link\>\` elements, one per line

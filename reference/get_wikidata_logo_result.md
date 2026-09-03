# Look up an organisation's logo on Wikidata

ROR carries no logo, so the landing page takes one from the Wikidata
item the ROR record points at: \`P154\` (logo image), or \`P18\` (image)
when there is no logo. Both are Commons filenames, which resolve to a
file through Special:FilePath without an API key.

## Usage

``` r
get_wikidata_logo_result(qid)
```

## Arguments

- qid:

  A Wikidata item id, e.g. "Q752663".

## Value

A list with \`status\` and \`value\`, the logo URL or \`NA_character\_\`

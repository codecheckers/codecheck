# Extract a citation\_\* publication-date meta tag from an HTML page

Checks, in priority order, \`citation_online_date\` (the earliest date a
work was made public - preprints, early view),
\`citation_publication_date\` and \`citation_date\`: the Highwire Press
/ Google Scholar metadata tags academic publisher and repository
platforms embed (arXiv, TU/e's Pure repository, ACL Anthology,
Copernicus journals, ...).

## Usage

``` r
extract_citation_meta_date(html_text)
```

## Arguments

- html_text:

  The page's HTML source

## Value

The tag's raw \`content\` string, or NA_character\_ if none present

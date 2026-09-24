# The current text of pages on the instance

The current text of pages on the instance

## Usage

``` r
wikibase_page_content(handle, titles)
```

## Arguments

- handle:

  an \`httr\` handle, or \`NULL\` to read anonymously

- titles:

  the page titles

## Value

a character vector named by title, \`NA\` for a page that does not exist

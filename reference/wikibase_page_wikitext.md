# The wikitext of one generated page

The generator for every page in \[WIKIBASE_PAGES\], in one place, so
that a page in the registry without one is an error rather than a page
nobody writes.

## Usage

``` r
wikibase_page_wikitext(key, context = NULL)
```

## Arguments

- key:

  a name of \[WIKIBASE_PAGES\]

- context:

  what the generators need, see \[wikibase_page_context()\]; a page that
  needs nothing from it does not touch it

## Value

the page's wikitext, one line per element

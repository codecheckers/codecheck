# Normalize a paper title for near-duplicate comparison

Case, punctuation and whitespace only - deliberately loose, since the
point is to catch the same paper recorded twice with slightly different
formatting (e.g. a certificate's own "Title" typed by hand rather than
pasted), not to be a general string-similarity metric.

## Usage

``` r
normalize_title_for_comparison(title)
```

## Arguments

- title:

  A paper title, or \`NA\`.

## Value

The normalized title, or \`NA_character\_\`.

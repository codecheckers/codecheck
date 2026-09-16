# Split a venue's hashtags

venues.csv writes them \`;\`-separated and without \`#\`, like the
separators in \`identifiers\`. A \`#\` written anyway is dropped rather
than doubled.

## Usage

``` r
split_venue_hashtags(hashtags)
```

## Arguments

- hashtags:

  The raw column value, possibly \`NA\`.

## Value

A character vector of hashtags without \`#\`, possibly empty.

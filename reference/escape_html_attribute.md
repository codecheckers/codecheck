# Escape a value for use in an HTML attribute

The values of \`\<meta\>\` tags are HTML attributes, and Google
Scholar's indexing guidelines are explicit that they have to be escaped,
\<https://scholar.google.com/intl/en/scholar/inclusion.html#indexing\>.
Certificate metadata routinely contains ampersands and quotes, in paper
titles as much as in the free text summary of a check.

## Usage

``` r
escape_html_attribute(x)
```

## Arguments

- x:

  A character value

## Value

The value with \`&\`, \`\<\`, \`\>\`, \`"\` and \`'\` replaced by
entities

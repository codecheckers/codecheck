# Render a codechecker's checks-per-type as a stacked bar (register#92)

A row of CSS-sized \`\<i\>\` segments rather than a canvas or an image:
the table has one of these per codechecker, and the underlying numbers
change with every render, so nothing here may be pre-rendered.

## Usage

``` r
codechecker_type_bar_html(counts)
```

## Arguments

- counts:

  A named integer vector of checks per venue type.

## Value

An HTML string, or \`""\` for no counts.

## Details

Every segment carries the same full-breakdown \`title\` as the wrapper,
so whichever segment the pointer lands on the reader sees the whole
picture. \`&#10;\` is a newline inside an HTML attribute value, which
native tooltips honour.

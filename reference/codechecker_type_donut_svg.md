# Render a codechecker's checks-per-type as an SVG donut (register#207)

Inline SVG rather than a charting library: the donut sits at 96px beside
the avatar, and a Chart.js tooltip is painted \*inside\* its canvas, so
a multi-line one is clipped at that size. Native SVG \`\<title\>\`
tooltips are drawn by the browser outside the element and cannot be
clipped - and they are the same hover mechanism as the stacked bar in
the codecheckers table.

## Usage

``` r
codechecker_type_donut_svg(counts)
```

## Arguments

- counts:

  A named integer vector of checks per venue type.

## Value

An SVG string, or \`""\` for no counts.

## Details

Every slice's \`\<title\>\` lists \*all\* types (see
\[type_breakdown_text()\]), marking its own, which is what lets the
chart do without a legend.

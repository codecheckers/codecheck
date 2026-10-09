# Create side-by-side comparisons of published and reproduced figures

Combines each published figure with the corresponding reproduced figure
into one image, with a label below each, so that differences can be seen
at a glance in the certificate. Both images are scaled to the same
width; only the first page or frame of an image file is used. PDF and
SVG figures are rendered at a resolution that fits `width`. The font
size of long labels is reduced so that they fit. Include the comparisons
in the certificate with
[`render_figure_comparisons`](http://codecheck.org.uk/codecheck/reference/render_figure_comparisons.md).

## Usage

``` r
compare_figures(
  published,
  reproduced,
  output_dir = "comparison",
  names = sprintf("comparison-%d.jpg", seq_along(published)),
  labels = c("Published", "Reproduced"),
  layout = c("vertical", "horizontal"),
  width = 1600,
  quality = 85
)
```

## Arguments

- published:

  Paths to the published figures, e.g., from
  [`extract_pdf_figures`](http://codecheck.org.uk/codecheck/reference/extract_pdf_figures.md).

- reproduced:

  Paths to the reproduced figures, in the same order.

- output_dir:

  Directory to write the comparison images to; created if missing.

- names:

  File names of the comparison images, ending in `.jpg`, `.jpeg`, or
  `.png`; default `comparison-1.jpg`, `comparison-2.jpg`, etc.

- labels:

  Labels for the published and the reproduced figure.

- layout:

  `"vertical"` (default) puts the published figure above the reproduced
  one, `"horizontal"` puts them side by side.

- width:

  Width in pixels to which each figure is scaled.

- quality:

  JPEG quality of the comparison images.

## Value

A data frame with the columns `published`, `reproduced`, and `file`,
invisibly.

## Details

Make sure the license of the published figures allows their reuse, e.g.,
CC BY, and attribute them in `labels`.

## Examples

``` r
if (FALSE) { # \dontrun{
comparisons <- compare_figures(
  published = figures$file[1:2],
  reproduced = c("outputs/Figure 1.png", "outputs/Figure 2.png"),
  labels = c("Published (Author et al., 2026, CC BY 4.0)", "Reproduced (CODECHECK)"))
} # }
```

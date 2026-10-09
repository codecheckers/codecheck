# Extract figures from the PDF of a published article

Extracts the raster images embedded in a PDF, e.g., the article being
checked, so that they can be compared with the reproduced figures using
[`compare_figures`](http://codecheck.org.uk/codecheck/reference/compare_figures.md).
With `method = "pdfimages"`, the images are extracted at their original
resolution with the `pdfimages` tool from poppler-utils, JPEG images as
JPEG and all others as PNG, and images smaller than `min_size` pixels in
width or height (e.g., logos, icons) are skipped. With
`method = "pages"`, whole pages are rendered with
[`pdftools::pdf_convert()`](https://docs.ropensci.org/pdftools//reference/pdf_render_page.html)
instead, e.g., for vector figures that are not embedded as images; crop
them with
[`magick::image_crop()`](https://docs.ropensci.org/magick/reference/transform.html)
if needed.

## Usage

``` r
extract_pdf_figures(
  pdf,
  dest_dir = "published",
  pages = NULL,
  min_size = 300,
  method = c("auto", "pdfimages", "pages"),
  dpi = 150,
  prefix = "figure"
)
```

## Arguments

- pdf:

  Path to the PDF file.

- dest_dir:

  Directory to write the images to; created if missing.

- pages:

  Page numbers to extract from; `NULL` for all pages.

- min_size:

  Minimum width and height in pixels of an embedded image to be
  extracted (only for `method = "pdfimages"`).

- method:

  `"auto"` (default) uses `"pdfimages"` if the `pdfimages` tool is
  available and `"pages"` otherwise.

- dpi:

  Resolution for rendering pages (only for `method = "pages"`).

- prefix:

  File name prefix of the extracted images.

## Value

A data frame with one row per extracted image and the columns `page`,
`width`, `height`, and `file`, invisibly.

## Details

The order of embedded images in a PDF does not always follow the page
layout, so check the extracted images against the figure captions.

## Examples

``` r
if (FALSE) { # \dontrun{
figures <- extract_pdf_figures("article.pdf", "published", pages = 6:12)
} # }
```

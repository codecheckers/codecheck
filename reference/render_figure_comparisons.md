# Include figure comparisons in the certificate

Writes Markdown to include the images created by
[`compare_figures`](http://codecheck.org.uk/codecheck/reference/compare_figures.md)
in the certificate, one per figure with a caption. Use it in a chunk
with `results = "asis"`.

## Usage

``` r
render_figure_comparisons(files, captions = basename(files), width = "85%")
```

## Arguments

- files:

  Paths to the comparison images, relative to the certificate source
  file.

- captions:

  Captions of the figures; default is the file name.

- width:

  Width of the figures in the certificate.

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

## Examples

``` r
if (FALSE) { # \dontrun{
render_figure_comparisons(comparisons$file,
  captions = paste("Figure", 1:2, "of the article: published (top) and reproduced (bottom)."))
} # }
```

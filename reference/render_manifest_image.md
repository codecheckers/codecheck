# Render single-page image for certificate output

Internal helper function to render PNG, JPG, JPEG, TIF, TIFF, GIF
images. TIF/TIFF and GIF files are automatically converted to PNG since
LaTeX doesn't natively support them.

## Usage

``` r
render_manifest_image(path, comment)
```

## Arguments

- path:

  \- Path to the image file

- comment:

  \- Comment/caption for the image

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

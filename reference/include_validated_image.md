# Include an image in the certificate after validating it

Internal helper: checks that the image file exists and can be read with
magick before writing the Markdown to include it, so that a missing or
corrupted image file shows an error box instead of breaking the LaTeX
compilation. The path is put in angle brackets, so that it may contain
spaces.

## Usage

``` r
include_validated_image(path, caption, name = basename(path), attributes = "")
```

## Arguments

- path:

  \- Path to the image file

- caption:

  \- Caption of the image

- name:

  \- File name shown in the error box

- attributes:

  \- Pandoc attributes of the image, e.g. `"{width=85%}"`

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

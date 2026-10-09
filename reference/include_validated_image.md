# Include an image in the certificate after validating it

Internal helper: checks that the image file exists and can be read with
magick before writing the Markdown to include it, so that a missing or
corrupted image file shows an error box instead of breaking the LaTeX
compilation. The path is put in angle brackets, so that it may contain
spaces.

## Usage

``` r
include_validated_image(
  path,
  caption,
  name = basename(path),
  attributes = "",
  base_dir = NULL
)
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

- base_dir:

  \- Directory the image is linked relative to, or `NULL` to link it by
  `path`; files are read by `path` either way

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

# Render Word or RTF file for certificate output

Internal helper function to render DOCX and RTF files, converted to
Markdown with pandoc. The format is detected by content, not by
extension, because some packages (e.g. apaTables) write RTF to \`.doc\`
files. Binary Word 97 \`.doc\` files are not supported by pandoc and get
a note instead. Images in Word files are extracted next to the file;
images LaTeX cannot include (e.g. EMF, WMF) are replaced by a note.

## Usage

``` r
render_manifest_office(path, comment, name = basename(path), base_dir = NULL)
```

## Arguments

- path:

  \- Path to the Word or RTF file

- comment:

  \- Comment describing the file

- name:

  \- File name shown in the heading and messages (default: the base name
  of `path`)

- base_dir:

  \- Directory the image is linked relative to, or `NULL` to link it by
  `path`; files are read by `path` either way

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

# Render manifest files for certificate output

Render manifest files for certificate output

## Usage

``` r
render_manifest_files(
  manifest_df,
  json_max_lines = 50,
  base_dir = quarto_document_dir()
)
```

## Arguments

- manifest_df:

  \- data frame with manifest file information (from
  copy_manifest_files)

- json_max_lines:

  \- Maximum number of lines to display for JSON files (default: 50)

- base_dir:

  \- Directory to link the images relative to, or \`NULL\` to link them
  by their paths in \`manifest_df\`. Defaults to the document's
  directory when Quarto renders it, and \`NULL\` otherwise. Files are
  read by their paths in \`manifest_df\` either way.

## Value

NULL (outputs directly via cat() for knitr/rmarkdown)

## Details

Renders each file in the manifest appropriately based on its file type.
Supported formats include images (PNG, JPG, JPEG, GIF, PDF, TIF, TIFF,
EPS, SVG), text files (TXT, Rout), tabular data (CSV, TSV) with skimr
statistics, Excel files (XLS, XLSX), Word and RTF documents (DOCX, RTF,
and RTF saved as DOC; converted to Markdown with pandoc), JSON files
(pretty-printed), and HTML files (converted to PDF via wkhtmltopdf).
Binary Word 97 DOC files are not supported and get a note.

For PDF files that contain multiple pages, all pages are included using
\includepdf\[pages={-}\]. Page count is determined using the pdftools
package. SVG files are converted to PDF using the rsvg package. TIF/TIFF
and GIF files are converted to PNG using the magick package (must be
installed). EPS files are included directly (LaTeX handles the
conversion with epstopdf package). JSON files are pretty-printed with a
configurable line limit.

Error handling: If a file is missing, corrupted, or cannot be processed,
an error box is displayed in the certificate output instead of failing
the entire rendering. This allows codecheckers to identify and fix
issues with individual files without blocking the certificate
generation.

## Author

Daniel Nuest

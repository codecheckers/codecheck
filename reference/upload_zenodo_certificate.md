# Upload the CODECHECK certificate and additional files to Zenodo.

Upload the CODECHECK certificate and optional additional files to
Zenodo.

## Usage

``` r
upload_zenodo_certificate(
  zenodo,
  record,
  certificate,
  upload_source = TRUE,
  additional_files = NULL,
  warn = TRUE
)

set_zenodo_certificate(
  zenodo,
  record,
  certificate,
  upload_source = TRUE,
  additional_files = NULL,
  warn = TRUE
)
```

## Arguments

- zenodo:

  \- Object from zen4R to interact with Zenodo

- record:

  \- either a string/numeric containing the record ID, or a Zenodo
  record object. If a record ID is provided, the function will fetch the
  record; if a record object is provided, it will be used directly.

- certificate:

  name of the PDF certificate file.

- upload_source:

  logical; if TRUE (default), also uploads the source file (.Rmd or
  .qmd) with the same base name as the certificate. The function first
  looks for a .Rmd file, then for a .qmd file if no .Rmd is found.

- additional_files:

  character vector of additional file paths to upload (optional). These
  files are uploaded after the certificate and source file.

- warn:

  logical; if TRUE (default), prompts user before deleting existing
  files. If FALSE, automatically deletes existing files without
  prompting (useful for non-interactive/automated contexts).

## Value

list with upload results: certificate result, source result (if
uploaded), and additional_files results

## Details

Upload the CODECHECK certificate PDF to Zenodo as a draft, along with
the certificate source file (Rmd or qmd) if found, and any additional
files. The certificate is always uploaded first to ensure it becomes the
preview file for the record. The source file is automatically detected
by looking for a file with the same base name as the certificate but
with .Rmd or .qmd extension. If certificate or source files already
exist on the Zenodo record, the user is prompted whether to delete the
existing files and upload the new ones, or abort the operation. This
applies separately to PDF certificates and source files, allowing
fine-grained control over what gets replaced.

## Author

Stephen Eglen

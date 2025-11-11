# Create or retrieve Zenodo record, submit to CODECHECK community, and update codecheck.yml

Create a new Zenodo record and automatically update codecheck.yml

## Usage

``` r
get_or_create_zenodo_record(
  zen,
  metadata = codecheck_metadata(getwd()),
  warn = TRUE,
  yml_file = "codecheck.yml"
)
```

## Arguments

- zen:

  Object from zen4R to interact with Zenodo

- metadata:

  codecheck.yml metadata (list). Defaults to loading from codecheck.yml
  in the current working directory using `codecheck_metadata(getwd())`.

- warn:

  Logical. If TRUE (default), asks for user confirmation before creating
  a new record or overwriting an existing non-placeholder DOI. If FALSE,
  skips interactive prompts (useful for non-interactive contexts).

- yml_file:

  Path to the codecheck.yml file to update. Defaults to "codecheck.yml"
  in the current directory.

## Value

Zenodo record object (ZenodoRecord)

## Details

Run this only once per new codecheck. By default, loads metadata from
codecheck.yml in the current working directory.

If a Zenodo record already exists (valid Zenodo DOI in report field),
retrieves it. If no valid Zenodo DOI exists, creates a new record,
submits it to the CODECHECK community on Zenodo, and updates
codecheck.yml: - Automatically submits new records to the CODECHECK
community (https://zenodo.org/communities/codecheck/) - If report field
is empty or contains a placeholder (FIXME, TODO, etc.): Updates
automatically - If report field contains a non-placeholder value: Asks
user before overwriting (when warn=TRUE)

## Author

Stephen Eglen

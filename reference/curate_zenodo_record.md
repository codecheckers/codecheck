# Curate a published Zenodo record per the CODECHECK curation policy

Curate a published Zenodo record to comply with the CODECHECK curation
policy

## Usage

``` r
curate_zenodo_record(
  record,
  zenodo = NULL,
  metadata = NULL,
  register_dir = getwd(),
  dry_run = TRUE,
  record_metadata = NULL,
  fields = c("title", "publisher", "language", "resource_type", "identifiers", "reviews",
    "repository", "creators", "license"),
  creator_overrides = list()
)
```

## Arguments

- record:

  certificate ID, Zenodo record ID, or Zenodo DOI

- zenodo:

  a \`zen4R\` ZenodoManager; only needed when \`dry_run = FALSE\`.
  Defaults to a manager built from the \`ZENODO_TOKEN\` environment
  variable.

- metadata:

  codecheck metadata (list); defaults to the \`codecheck.yml\` of the
  repository registered for the certificate

- register_dir:

  directory holding \`register.csv\`, defaults to the working directory

- dry_run:

  if TRUE (the default) only report what would change

- record_metadata:

  the current record metadata as returned by
  \[get_zenodo_record_metadata()\]; fetched from Zenodo when NULL (the
  default). Mainly useful for testing and for auditing a record offline.

- fields:

  which classes of correction to consider. Defaults to all of "title",
  "publisher", "language", "resource_type", "identifiers", "reviews",
  "repository" and "creators". The first seven are mechanical: their
  target value follows from the certificate ID or from
  \`codecheck.yml\`. "creators" is not: splitting a name into given and
  family name is wrong for group entries such as "Delft 2024-05
  participants", so exclude it from batch runs and review those records
  individually.

- creator_overrides:

  named list keyed by the creator name as currently recorded,
  controlling how that creator is handled. Use \`list(organizational =
  TRUE)\` to keep an entry as an organisation (correct for a group such
  as "Delft 2024-05 participants"), or \`list(given = "Gabriella",
  family = "Low Chew Tung")\` to give an explicit split where the
  last-token heuristic of \[split_person_name()\] is wrong.

## Value

invisibly, a list of the proposed changes

## Details

Computes the metadata corrections needed to bring a published
certificate record in line with the CODECHECK community curation policy,
prints them, and - only with \`dry_run = FALSE\` - applies them by
editing the published record and publishing the metadata update. No new
file version is created.

The target values come from the \`codecheck.yml\` of the checked
repository, which is the source of truth for certificate ID, paper
reference and codechecker names.

Requires a Zenodo token with write access, see \`zen4R::ZenodoManager\`.

## Author

Daniel Nuest

# Print a latex table to summarise CODECHECK metadata

Print a latex table to summarise CODECHECK manfiest

## Usage

``` r
latex_summary_of_manifest(
  metadata,
  manifest_df,
  root,
  align = c("l", "p{6cm}", "p{6cm}", "p{2cm}"),
  repository_url = NULL
)
```

## Arguments

- metadata:

  \- the CODECHECK metadata list.

- manifest_df:

  \- The manifest data frame

- root:

  \- root directory of the project

- align:

  \- alignment flags for the table.

- repository_url:

  \- the repository to link the output files to. By default, the first
  GitHub or GitLab repository in the metadata, linked on its default
  branch; other repositories and DOIs are not linked. A string links to
  that repository, \`FALSE\` turns the links off.

## Value

The latex table, suitable for including in the Rmd

## Details

Format a latex table that summarises the main CODECHECK manifest

## Author

Stephen Eglen

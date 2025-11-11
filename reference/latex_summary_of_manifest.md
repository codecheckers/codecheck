# Print a latex table to summarise CODECHECK metadata

Print a latex table to summarise CODECHECK manfiest

## Usage

``` r
latex_summary_of_manifest(
  metadata,
  manifest_df,
  root,
  align = c("l", "p{6cm}", "p{6cm}", "p{2cm}")
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

## Value

The latex table, suitable for including in the Rmd

## Details

Format a latex table that summarises the main CODECHECK manifest

## Author

Stephen Eglen

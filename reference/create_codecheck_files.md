# Create template files for the codecheck process.

Create template files for the codecheck process.

## Usage

``` r
create_codecheck_files(template = c("all", "rmd", "qmd"))
```

## Arguments

- template:

  Which certificate source template(s) to copy: \`"all"\` (default)
  copies both the R Markdown (\`codecheck.Rmd\`) and Quarto
  (\`codecheck.qmd\`) templates, \`"rmd"\` copies only
  \`codecheck.Rmd\`, and \`"qmd"\` copies only \`codecheck.qmd\`.
  Shipping both is convenient while deciding, but only one should end up
  committed/published, since having both makes it unclear which is the
  canonical certificate source (see the sibling-template warnings in
  each template and the Zenodo policy check in
  \`zenodo_policy_check()\`).

## Value

Nothing

## Details

This function simply creates some template files to help start the
codecheck process. If either ./codecheck.yml or codecheck/ exists then
it assumes you have already started codechecking, and so will not copy
any files across.

## Author

Stephen J. Eglen

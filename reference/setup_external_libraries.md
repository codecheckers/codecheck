# Download and Setup External Libraries Locally

Downloads CSS and JavaScript libraries from their official sources and
stores them locally in the docs/libs directory. This removes dependency
on external CDNs and ensures reproducibility.

## Usage

``` r
setup_external_libraries(libs_dir = "docs/libs", force = FALSE)
```

## Arguments

- libs_dir:

  Directory where libraries should be installed (default: "docs/libs")

- force:

  If TRUE, re-download libraries even if they already exist

## Value

Invisibly returns a data frame with provenance information for all
libraries

## Details

Files that are already present and of a plausible size are not
downloaded again. When all expected files are present and
\`PROVENANCE.csv\` matches the current library versions, the function
returns early and leaves \`PROVENANCE.csv\` and \`README.md\` untouched,
so that repeated rendering does not modify these files.

# codecheck

`codecheck` is an R package to assist codecheckers in creating
CODECHECK-ready workspaces and conducting codechecks. This package
focuses on the technical workflow for codecheckers using R. It also
contains helper functions for managing the [CODECHECK
register](https://codecheck.org.uk/register/).

For general information about the CODECHECK initiative and community
processes, visit <https://codecheck.org.uk/>.

## Installation

The package is not on [CRAN](https://CRAN.R-project.org) yet. Install
the current version from
[GitHub](https://github.com/codecheckers/codecheck) with:

``` r
# install.packages("remotes")
remotes::install_github("codecheckers/codecheck")
```

## Quick Start

For first-time codecheckers using this R package:

1.  **Fork the research repository** - Fork to the [codecheckers
    organization](https://github.com/codecheckers) on GitHub
2.  **Clone and navigate to the repository root** - Run R from the
    top-level directory of the research project
3.  **Create CODECHECK files** - Run
    [`codecheck::create_codecheck_files()`](http://codecheck.org.uk/codecheck/reference/create_codecheck_files.md)
    to generate:
    - A `codecheck.yml` configuration file with metadata (certificate
      ID, authors, manifest, etc.)
    - A `codecheck/` directory with report templates
4.  **Define the manifest** - List all computational outputs (figures,
    tables, data files) that you’ve successfully reproduced in the
    `manifest` section of `codecheck.yml`
5.  **Complete the certificate** - Fill in the report template and
    render it
6.  **Create a record on Zenodo** (or OSF, or ResearchEquals) and submit
    the draft for feedback to your CODECHECK editor/contact person,
    e.g., via a sharing link or the CODECHECK Zenodo community; push the
    `codecheck.yml` to the repository

## Key Concepts

- **Certificate** - The final report documenting your CODECHECK, which
  includes metadata, the manifest, and your assessment.
- **codecheck.yml** - The configuration file containing all CODECHECK
  metadata (paper details, authors, manifest, etc.)
- **Manifest** - A list of computational output files (figures, data
  files, tables) that you have successfully reproduced during the
  CODECHECK. Each manifest entry includes the file path and a brief
  description. The manifest is defined in the `codecheck.yml`.

## Usage

See the [getting started
guide](https://codecheck.org.uk/codecheck/articles/codecheck_overview.html)
for step-by-step instructions on using the template and the [workflow
descriptions](https://codecheck.org.uk/workflows/) on the overall
procedures.

**Note on certificate templates**: The R Markdown template created by
this package can be used in multiple ways:

- Execute code in various languages (R, Python, bash, etc.) using
  knitr’s language engines
- Simply write your certificate narrative without executing any code
- Mix both approaches as needed

If you prefer working with Jupyter Notebooks (especially for
Python-based projects), see the [Python CODECHECK
template](https://github.com/codecheckers/codecheck-py) based on a
Jupyter Notebook.

## Development

The package uses
[`tinytest`](https://cran.r-project.org/package=tinytest) for tests. Run
`test_all("/path/to/package")` to run all tests interactively. Even
better, run the tests in a fresh install and temporary directory using

``` r
# assuming . is the package path
library(tinytest)
build_install_test(".")
```

## Contribute

*All contributions are welcome!* See
[CONTRIBUTING.md](http://codecheck.org.uk/codecheck/CONTRIBUTING.md) for
details.

## Code of Conduct

Please note that the codecheck project is released with a [Contributor
Code of Conduct](http://codecheck.org.uk/codecheck/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.

## License

Copyright 2025 S. Eglen & D. Nüst. The `codecheck` package is published
under the MIT license, see file `LICENSE`.

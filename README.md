
<!-- README.md is generated from README.Rmd. Please edit that file -->

# codecheck

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R build
status](https://github.com/codecheckers/codecheck/workflows/R-CMD-check/badge.svg)](https://github.com/codecheckers/codecheck/actions)
[![DOI](https://zenodo.org/badge/256862293.svg)](https://zenodo.org/badge/latestdoi/256862293)
<!-- badges: end -->

`codecheck` is an assistant for conducting CODECHECKs, written in the R
language and distributed as an R package. The goal of codecheck is to
ease the process to create a CODECHECK-ready workspace, and to conduct
the actual CODECHECK. Furthermore, the package contains some helper
functions for managing the [CODECHECK
register](https://codecheck.org.uk/register/).

**Learn more about CODECHECK on <https://codecheck.org.uk/>.**

## Installation

The package is not on [CRAN](https://CRAN.R-project.org) yet. Install
the development version from
[GitHub](https://github.com/codecheckers/codecheck) with:

``` r
# install.packages("remotes")
remotes::install_github("codecheckers/codecheck")
```

## Usage

See the [main vignette](https://github.com/codecheckers/codecheck/blob/master/vignettes/codecheck_overview.Rmd).

tl;dr: Go the the directory where you want to create a CODECHECK workspace, then run

```r
require("codecheck")
create_codecheck_files()
```

## Development

The package uses
[`tinytest`](https://cran.r-project.org/package=tinytest) for tests. Run
`test_all("/path/to/package")` to run all tests interactively. Even
better, run the tests in a fresh install/temporary directory using

``` r
# assuming . is the package path
build_install_test(".")
```

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## License

Copyright 2025 S. Eglen & D. Nüst. The `codecheck` package is published
under the MIT license, see file `LICENSE`.

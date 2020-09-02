
<!-- README.md is generated from README.Rmd. Please edit that file -->

# codecheck

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Travis build
status](https://travis-ci.com/nuest/codecheck.svg?branch=master)](https://travis-ci.com/nuest/codecheck)
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
[GitHub](https://github.com/codecheckers/codecheck) with: Note this
currently requires the development version of `zen4R`.

``` r
# install.packages("remotes")
remotes::install_github("eblondel/zen4R")
remotes::install_github("codecheckers/codecheck")
```

## Usage

See the main vignette.

## Development

The package uses
[`tinytest`](https://cran.r-project.org/package=tinytest) for tests. Run
`test_all("/path/to/package")` to run all tests interactively. Even
better, run the tests in a fresh install/temporary directory using

``` r
# assuming . is the package path
build_install_test(".")
```

## License

Copyright 2020 S. Eglen & D. Nüst. The `codecheck` package is published
under the MIT license, see file `LICENSE`.

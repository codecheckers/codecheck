# codecheck

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

See the [main
vignette](https://github.com/codecheckers/codecheck/blob/master/vignettes/codecheck_overview.Rmd).

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

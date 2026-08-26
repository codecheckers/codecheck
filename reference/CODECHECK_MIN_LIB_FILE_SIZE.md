# Minimum plausible size of a downloaded library file, in bytes

Downloads that fail with an HTTP error page, or that are interrupted,
can leave a small file behind. Such a file must not count as a valid
local copy, otherwise it is never downloaded again. The smallest file of
the libraries handled here is about 7 kB.

## Usage

``` r
CODECHECK_MIN_LIB_FILE_SIZE
```

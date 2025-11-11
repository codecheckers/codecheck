# codecheck: Render the register

## Installing the package

The latest version of the package can be installed using:

``` r
remotes::install_github("codecheckers/codecheck")
```

## Render the register

``` r
codecheck::register_render(); warnings()
```

## Check the register

``` r
codecheck::register_check(); warnings()
```

## Clear the cache

``` r
codecheck::register_clear_cache();
```

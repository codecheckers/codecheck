# The venue of a certificate as recorded in the register

The venue of a certificate as recorded in the register

## Usage

``` r
lookup_register_venue(record, register_dir)
```

## Arguments

- record:

  a certificate ID; anything else yields NULL, the venue of a module
  referenced by DOI cannot be looked up

- register_dir:

  directory holding \`register.csv\`

## Value

the venue as a string, or NULL when it cannot be determined

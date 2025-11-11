# Validate a CODECHECK configuration

This functions checks "MUST"-contents only, see
https://codecheck.org.uk/spec/config/latest/

## Usage

``` r
validate_codecheck_yml(configuration)
```

## Arguments

- configuration:

  R object of class \`list\`, or a path to a file

## Value

\`TRUE\` if the provided configuration is valid, otherwise the function
stops with an error

## Author

Daniel Nüst

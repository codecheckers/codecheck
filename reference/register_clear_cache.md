# Function for clearing the register cache

Removes everything cached below the R.cache root: the codecheck.yml
files, the codecheckers table, and the looked up OpenAlex IDs and
abstracts. Use it to pick up metadata that has changed at the source,
the lookups themselves never cache a failed request.

## Usage

``` r
register_clear_cache()
```

## Value

0 for success, 1 for failure, invisibly (see \`unlink\`)

## Author

Daniel Nuest

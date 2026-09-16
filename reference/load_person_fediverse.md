# Read the fediverse accounts recorded in persons.csv

Fills \`CONFIG\$PERSON_FEDIVERSE\`, a named character vector from ORCID
to account. A file without the column, or no file, is an empty lookup
rather than an error: the column is optional.

## Usage

``` r
load_person_fediverse(persons_file = NULL)
```

## Arguments

- persons_file:

  Path to the CSV, or \`NULL\`.

## Value

The lookup, invisibly.

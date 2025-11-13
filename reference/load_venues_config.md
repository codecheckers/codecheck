# Load venues configuration from CSV file

Reads a venues.csv file and constructs the CONFIG\$DICT_VENUE_NAMES
dictionary and stores full venue information including labels.

## Usage

``` r
load_venues_config(venues_file = NULL)
```

## Arguments

- venues_file:

  Path to the venues.csv file. If NULL, defaults to "venues.csv" in the
  current working directory.

## Value

A data frame with columns: name, longname, label

## Author

Daniel Nüst

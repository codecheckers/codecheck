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

A data frame with the required columns name, longname, label, plus
whatever optional metadata columns the file carries (e.g. logo_url,
website_url, policy_url, publisher) - passed through unchanged for
consumers like \[compute_annual_stats()\].

## Author

Daniel Nuest

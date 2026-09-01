# Generate navigation header with logo and menu

Creates a header navigation bar with CODECHECK logo and optional menu.
The logo links to register home, same as the "All Checks" menu item -
kept as a second, explicit route to the same place since a logo-as-home
link is a common web convention but not a self-explanatory one, and the
logo also carries a hover title saying so.

## Usage

``` r
generate_navigation_header(
  filter = NA,
  base_path = ".",
  table_details = list()
)
```

## Arguments

- filter:

  The filter type (NA for main register, "venues", "works", "persons",
  "statistics", ...)

- base_path:

  Relative path to register root for logo link

- table_details:

  List containing page metadata to determine if it's an overview page

## Value

HTML string with navigation header

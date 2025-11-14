# Generate navigation header with logo and menu

Creates a header navigation bar with CODECHECK logo and optional menu.
Logo links to register home. Menu appears on main register and overview
pages.

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

  The filter type (NA for main register, "venues", "codecheckers", etc.)

- base_path:

  Relative path to register root for logo link

- table_details:

  List containing page metadata to determine if it's an overview page

## Value

HTML string with navigation header

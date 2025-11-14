# Generate breadcrumb navigation HTML

Creates Bootstrap-styled breadcrumb navigation based on page context.
Breadcrumbs help users navigate from detail pages back to overview
pages.

## Usage

``` r
generate_breadcrumb(filter = NA, table_details = list(), base_path = ".")
```

## Arguments

- filter:

  The filter type (NA for main register, "venues", "codecheckers",
  "certs")

- table_details:

  List containing page metadata (name, subcat, slug_name, is_reg_table)

- base_path:

  Relative path to register root (e.g., "../..", ".", etc.)

## Value

HTML string with breadcrumb navigation

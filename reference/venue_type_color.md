# Colour for a venue type

Named lookup in \`CONFIG\$VENUE_TYPE_COLORS\`, so the statistics page,
the codecheckers table (register#92) and the codechecker donut
(register#207) all colour a given venue type the same way. Any type not
in the map gets \`CONFIG\$VENUE_TYPE_COLOR_FALLBACK\` rather than
another type's colour.

## Usage

``` r
venue_type_color(type)
```

## Arguments

- type:

  A venue type, e.g. \`"journal"\`.

## Value

A hex colour string.

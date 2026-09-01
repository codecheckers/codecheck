# Escape text for inclusion in HTML/SVG

Small local helper rather than a new dependency on htmltools - the only
escaping the register needs is for the venue-type names and counts that
go into the check-type visualisations.

## Usage

``` r
html_escape(text, attribute = FALSE)
```

## Arguments

- text:

  The text to escape.

- attribute:

  Whether the text goes into an attribute value (also escapes quotes)
  rather than element content.

## Value

The escaped text.

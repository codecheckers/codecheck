# Render a codechecker's contributed-venues list as an HTML fragment

Produces the register#83 target format - \`type \<a
href="..."\>Name\</a\> (count)\` entries, comma-separated (no
surrounding label; the caller/template supplies that, see
\`codechecker_metadata.html\`). Reuses \`add_venue_hyperlinks_reg()\`
for the venue links so they match exactly what the same register_table
would produce elsewhere on the page.

## Usage

``` r
generate_contributed_venues_html(register_table, table_details)
```

## Arguments

- register_table:

  See \[get_codechecker_venues()\].

- table_details:

  Needed for \`add_venue_hyperlinks_reg()\`'s relative-path depth
  calculation.

## Value

An HTML string, or \`""\` if there are no venues.

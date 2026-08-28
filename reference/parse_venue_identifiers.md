# Parse a venue's identifiers string into a list usable by whisker

Identifiers are stored in venues.csv as a single column: \`;\`-separated
entries, each a \`name\|icon\|value\|url\` quadruple (\`icon\` and
\`url\` are optional - pipes may be omitted from the right, e.g.
\`name\|icon\|value\` or just \`name\|icon\`), e.g.
\`ISSN\|fa-book\|2047-217X\|https://portal.issn.org/resource/ISSN/2047-217X;ROR\|fa-university\|05wg1m734\|https://ror.org/05wg1m734\`.
\`icon\` is a Font Awesome class name (without the leading \`fa-\`
prefix already implied by the \`fa\` base class), rendered as \`\<i
class="fa icon"\>\`.

## Usage

``` r
parse_venue_identifiers(identifiers_str)
```

## Arguments

- identifiers_str:

  The raw identifiers string from venues.csv.

## Value

A list of lists, each with \`name\`, \`icon\`, \`value\` and \`link\`
(\`icon\`/\`link\` are \`NULL\` when not provided), ready to pass to
whisker.render.

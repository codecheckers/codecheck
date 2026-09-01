# Turn a single markdown link into an HTML anchor tag

The codechecker metadata panel is a raw HTML block passed through pandoc
unprocessed (like the venue metadata panel - see register#84 followup),
so a markdown-syntax link inside it would render as literal text rather
than a clickable link. \`add_venue_hyperlinks_reg()\` only produces
markdown links (\`\[Name\](url)\`), so its output is converted here
rather than duplicating its slug/relative-path logic in an HTML-emitting
copy.

## Usage

``` r
markdown_link_to_html(markdown_link)
```

## Arguments

- markdown_link:

  A string possibly containing \`\[text\](url)\` markdown links.

## Value

The same string with any markdown links replaced by \`\<a
href="url"\>text\</a\>\`.

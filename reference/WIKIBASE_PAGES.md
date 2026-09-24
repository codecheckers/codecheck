# The pages generated on the CODECHECK Wikibase

Every page the package writes, in one place: its title, the function
whose run writes it as a side effect, and - for a page a visitor should
be pointed at - the line the Main Page lists it with. The Main Page's
list is built from this, so a new page cannot be left off it, and
\[publish_wikibase_pages()\] rewrites all of them;
\[wikibase_page_wikitext()\] holds the generator for each.

## Usage

``` r
WIKIBASE_PAGES
```

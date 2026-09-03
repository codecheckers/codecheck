# The register.csv column holding a certificate's Wikidata item

Written by \[update_register_wikidata()\] after a batch has run, and
read back by the render so a certificate page can link the record it
exported. One column rather than two: a checked work's item is resolved
from its DOI at render time, and a person's from the register's person
lookup.

## Usage

``` r
WIKIDATA_REGISTER_COLUMN
```

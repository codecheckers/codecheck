# Whether a claim was written by the CODECHECK export alone

Every statement the export writes carries a reference URL into the
register (see \[WIKIDATA_REFERENCE\]). A claim all of whose references
are such URLs rests on the register alone, and when the register no
longer supports it the claim can go. One that somebody else referenced
as well is shared: the value may be wrong for our reasons and right for
theirs.

## Usage

``` r
wikidata_claim_provenance(claim)
```

## Arguments

- claim:

  one claim, with its references

## Value

\`"ours"\`, \`"shared"\` (ours among others) or \`"theirs"\`

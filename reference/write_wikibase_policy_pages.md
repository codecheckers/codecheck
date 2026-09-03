# Write the hosting-policy pages onto the instance

\`Project:About\` and \`Project:Copyrights\` are what the wikibase.cloud
hosting policy asks every hosted instance for, and a rebuilt instance
has to be compliant without a manual step, so they are written like the
generated index pages rather than curated by hand.
\`Project:Copyright\`, MediaWiki's own footer target, is left as a
redirect to the plural.

## Usage

``` r
write_wikibase_policy_pages(session)
```

## Arguments

- session:

  a session from \[wikibase_session()\]

## Value

the page titles, invisibly

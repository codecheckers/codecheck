# Open an authenticated session with the CODECHECK Wikibase

Uses the bot password in the \`WIKIBASE_USER\` and \`WIKIBASE_TOKEN\`
environment variables (see the register's \`.env.example\`). The
returned session carries the login cookies and a CSRF token, both of
which every write needs.

## Usage

``` r
wikibase_session()
```

## Value

a list with \`handle\` and \`csrf\`

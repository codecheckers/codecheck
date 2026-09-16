# The profile URL of a fediverse account

\`https://instance/@user\`, the form Mastodon and most other servers
answer to.

## Usage

``` r
fediverse_profile_url(handle)
```

## Arguments

- handle:

  An account, see \[fediverse_handle()\].

## Value

The URL, or \`NULL\` when \`handle\` is not an account.

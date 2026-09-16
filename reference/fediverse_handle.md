# Normalise a fediverse account to \`@user@instance\`

Accepts the form the columns are documented to hold, \`@user@instance\`,
and the same without the leading \`@\`. Anything else - a profile URL, a
bare \`@user\` with no instance - is not guessed at, because a wrong
guess would link a stranger's account.

## Usage

``` r
fediverse_handle(handle)
```

## Arguments

- handle:

  A character string, possibly \`NA\` or empty.

## Value

\`@user@instance\`, or \`NULL\` when \`handle\` is not one.

# The text of a link to a fediverse account

\`@user@instance\` with each \`@\` written as \`&#64;\`. The pages go
through pandoc, which reads \`@word\` in Markdown as a citation key and
wraps it in a citation span; an entity is text to it.

## Usage

``` r
fediverse_link_text(handle)
```

## Arguments

- handle:

  An account, see \[fediverse_handle()\].

## Value

The HTML text, or \`NULL\` when \`handle\` is not an account.

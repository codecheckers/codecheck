# Retrieves the abstract and reports whether the answer is conclusive

Same lookup as
[`get_abstract`](http://codecheck.org.uk/codecheck/reference/get_abstract.md)
without the caching, and with the information needed to decide whether
the result may be cached: a paper for which neither API has an abstract
is a conclusive answer, a paper whose requests failed is not, see
[`cached_lookup`](http://codecheck.org.uk/codecheck/reference/cached_lookup.md).

## Usage

``` r
get_abstract_result(register_repo)
```

## Arguments

- register_repo:

  URL or path to the repository containing the paper's configuration.

## Value

A list with \`status\` ("found", "absent" or "failed") and \`value\`,
the latter being the \`source\`/\`text\` list described in
[`get_abstract`](http://codecheck.org.uk/codecheck/reference/get_abstract.md)

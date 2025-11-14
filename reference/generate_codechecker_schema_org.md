# Generate Schema.org JSON-LD for codechecker pages

Creates structured metadata using @graph to represent the codechecker as
a Person and their Reviews (codechecks). Uses the proper Schema.org
relationship where each Review has an "author" property pointing to the
Person, rather than Person having a "review" property (which doesn't
exist in Schema.org). Enables better discoverability by search engines
and tools that consume schema.org metadata.

## Usage

``` r
generate_codechecker_schema_org(
  codechecker_orcid,
  codechecker_name,
  codechecker_github = NULL,
  register_table
)
```

## Arguments

- codechecker_orcid:

  The ORCID identifier of the codechecker

- codechecker_name:

  The name of the codechecker

- codechecker_github:

  Optional GitHub handle of the codechecker

- register_table:

  A data frame containing all codechecks by this codechecker

## Value

JSON-LD string with Schema.org metadata using @graph

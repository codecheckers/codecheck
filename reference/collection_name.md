# The short name of a ResearchEquals collection

The name from \[RESEARCHEQUALS_COLLECTIONS\] if the issue is one of the
collections the policy requires, otherwise the part of the collection
title before the en dash, e.g. "CODECHECK" out of "CODECHECK - CODECHECK
Certificates and Reproducibility Reports".

## Usage

``` r
collection_name(issue)
```

## Arguments

- issue:

  a collection issue as returned by \[get_researchequals_collection()\]

## Value

the short name as a string

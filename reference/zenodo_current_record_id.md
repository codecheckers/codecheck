# The record id a Zenodo record id now points at

Zenodo versions a record under a new id and redirects the old one. The
register stores the report DOI as it was published, so an edit aimed at
that id fails with "Not found" once a new version exists.

## Usage

``` r
zenodo_current_record_id(id)
```

## Arguments

- id:

  A Zenodo record id

## Value

The current id, or \`id\` unchanged when there is no redirect

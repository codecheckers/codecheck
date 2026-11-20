# The publication of the copy of a work a reference names

When an OpenAlex record describes another copy of the work as its
primary location, the location whose DOI is the reference's still says
where the referenced copy appeared.

## Usage

``` r
openalex_location_fields(fields, paper_reference)
```

## Arguments

- fields:

  The value of \[get_openalex_work_fields_cached_result()\]

- paper_reference:

  The paper reference from the register

## Value

A list with \`issn\` and \`venue\`, both \`NA\` when no location carries
the reference's DOI

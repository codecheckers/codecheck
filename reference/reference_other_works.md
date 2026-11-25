# The works the certificates name in \`reference-other\`, as export rows

A preprint and its article are both given an item, so that the one the
check was made on can say it is a version of the other
(codecheckers/register#247). Only a further reference that is not itself
a checked work is a row here, and only the other version: an article of
a checked preprint, a preprint of a checked article. Its OpenAlex ID is
the one its work page holds, which the render rejects for a record of
another copy even of the same kind (see \[openalex_record_is_copy()\]),
so such a reference has none. What the register knows of it comes from
its DOI's registry record (title, authors, date) and from the OpenAlex
ID the render found for its work page (publication); the reference
statements point at the certificate that names it.

## Usage

``` r
reference_other_works(certificates, dir)
```

## Arguments

- certificates:

  the certificates of \[read_register_records()\]

- dir:

  the register repository

## Value

a \`data.frame\` with the paper columns the model reads, or \`NULL\`

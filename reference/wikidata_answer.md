# Stop on an API answer that is an error

An error answer has no search hits and no entities, which would
otherwise read as "no item": with Wikidata's search overloaded, an
export once planned to create 40 works and 24 certificates that were
already there.

## Usage

``` r
wikidata_answer(answer, what)
```

## Arguments

- answer:

  the parsed API answer

- what:

  what was asked, for the message

## Value

\`answer\`, if it is not an error

# Whether a name with initials is one of these names written out

"J J Hopfield" is "John J. Hopfield" and "A. G. Toxopeus" is "Albertus G
Toxopeus": the family names are the same, and each given name is the
other's or the initial of it. Strict on purpose: the same number of
given names, so "J J Hopfield" is not "John Hopfield", and the family
name is the last one.

## Usage

``` r
wikidata_names_by_initials(proposed, current)
```

## Arguments

- proposed:

  one name

- current:

  names to compare with

## Value

\`TRUE\` if one of \`current\` matches

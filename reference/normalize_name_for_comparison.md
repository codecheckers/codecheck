# Normalize a person's name for conflict comparison

Reduced to "first initial + surname" (the last whitespace-separated
token, periods stripped) so that a spelled-out middle name, a missing
middle initial, or a full given name vs. its initial (all routine
transcription differences between a certificate's codecheck.yml and its
co-authors' own spelling) do not read as a conflict - only a materially
different name does. Not a general name-matching algorithm: a
double-barrelled surname written with a space in one certificate and a
hyphen in another can still produce a false positive here, and that is
an accepted trade-off for a check that only needs to flag "look at this
by hand", not adjudicate it.

## Usage

``` r
normalize_name_for_comparison(name)
```

## Arguments

- name:

  A person's name.

## Value

The normalized comparison key.

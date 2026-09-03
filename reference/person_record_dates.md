# The date a person's affiliation has to cover, per exploded person record

A codechecker's date is the register's check date - the check is the
thing they did for that organisation. An author's is the paper's
publication date from OpenAlex, which falls back to the check date for a
certificate without an OpenAlex ID, so every record has a date to match
against.

## Usage

``` r
person_record_dates(exploded)
```

## Arguments

- exploded:

  An exploded person table (see \[explode_person_records()\]), with the
  \`Check date\`, \`Role\` and (optionally) \`OpenAlex\` columns.

## Value

A data frame with columns \`date\` (a \`Date\`) and \`date_source\`
("openalex" or "check date"), one row per input row.

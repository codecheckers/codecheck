# Generate Schema.org JSON-LD for a person page (codecheckers/register#123)

Generalises \[generate_codechecker_schema_org()\] to a person's two
possible roles: the \`Person\` entity still gets a \`Review\` per
certificate they checked (identical to the codechecker version,
\`author\` referencing the person by \`@id\`), and additionally a
\`ScholarlyArticle\` per paper they authored, each with \`author: "@id":
person_id\` pointing back the other way. A person with only one role
simply has an empty list for the other.

## Usage

``` r
generate_person_schema_org(orcid, name, github_handle = NULL, register_table)
```

## Arguments

- orcid:

  The person's ORCID.

- name:

  The person's name.

- github_handle:

  Optional GitHub handle.

- register_table:

  The person's exploded, per-role register rows (see
  \[explode_person_records()\]), needs \`Certificate\`, \`Repository\`,
  \`Check date\` and \`Role\` columns.

## Value

JSON-LD string with Schema.org metadata using \`@graph\`.

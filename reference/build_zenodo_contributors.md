# Build the \`contributors\` array for the register's \`.zenodo.json\`

Every codechecker named in \`codecheck.yml\` across the register becomes
one Zenodo contributor (register#58), crediting people whose work the
register otherwise only lists on their own person page. Zenodo's
contributor role vocabulary
(\<https://zenodo.org/api/vocabularies/contributorsroles\>) has no
"reviewer" or "checker" term, so every entry is typed \`type\` (default
\`"Other"\`) - the record's own description is where that choice is
explained to a reader.

## Usage

``` r
build_zenodo_contributors(
  register,
  exclude = ZENODO_NON_PERSON_CODECHECKERS,
  type = "Other"
)
```

## Arguments

- register:

  The register data frame (as read from \`register.csv\`), with
  \`Repository\` and \`Certificate\` columns.

- exclude:

  Character vector of codechecker names to omit as not naming an
  individual. Defaults to \[ZENODO_NON_PERSON_CODECHECKERS\].

- type:

  The Zenodo contributor role to assign every entry.

## Value

A list of \`list(name=, orcid=, type=)\` records (\`orcid\` omitted when
not on record), sorted by name for a stable, diffable order.

## Details

Reads \`codecheck.yml\` directly (via \[get_codecheck_yml_or_null()\],
cached) rather than through \[add_codechecker()\]'s per-row identifiers,
because that column collapses every codechecker with neither an ORCID
nor a resolvable GitHub handle to the shared identifier \`"NA"\` - fine
for counting checks, but it would silently merge distinct people here.
Working from the raw name keeps them distinct; only
\[ZENODO_NON_PERSON_CODECHECKERS\] is treated as not-a-person.

A codechecker is deduplicated by normalized ORCID when they have one,
otherwise by their exact recorded name - so the same person named
identically across certificates contributes one entry, keeping the name
exactly as recorded in \`codecheck.yml\` (no "Family, Given"
reformatting: a heuristic split gets compound and multi-word family
names wrong, and the recorded spelling is the person's own).

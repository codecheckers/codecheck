# Update the \`contributors\` array of a \`.zenodo.json\` in place

\`.zenodo.json\` at the register repo root is otherwise hand-maintained
(title, creators, licence, community, ...); a render only keeps its
\`contributors\` current with the codecheckers named in the register
(register#58), so it needs no manual fix-up before the next Zenodo
deposit. Every other key is preserved exactly - the file is parsed with
\`simplifyVector = FALSE\` so key order and scalar-vs-array shape
survive the round trip.

## Usage

``` r
update_zenodo_json(register, path = ".zenodo.json")
```

## Arguments

- register:

  The register data frame, passed to \[build_zenodo_contributors()\].

- path:

  Path to the \`.zenodo.json\` file. Defaults to the repo root.

## Value

Invisibly, \`TRUE\` if the file was updated, \`FALSE\` if there was no
file to update.

## Details

A missing file is a no-op (with a message, not a warning): most working
directories a render runs in - a test fixture, a partial render's temp
copy - have no \`.zenodo.json\` at all, and that must never be an error.

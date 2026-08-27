# Prune Unreferenced Library Directories

\`docs/libs\` accumulates directories that nothing renders references
any more - most notably \`header-attrs-\<rmarkdown version\>\`, whose
name changes with every rmarkdown release even though the file itself
never does (see <https://github.com/codecheckers/codecheck/issues/89>).
Nothing else in the render pipeline removes an old directory once its
version stops being generated, so this scans every rendered HTML file
for \`libs/\<name\>/\` references and deletes the directories that no
file references.

## Usage

``` r
prune_libs(
  docs_dir = "docs",
  libs_dir = file.path(docs_dir, "libs"),
  dry_run = FALSE
)
```

## Arguments

- docs_dir:

  Root output directory that was rendered into (default "docs")

- libs_dir:

  Libraries directory to prune (default "\<docs_dir\>/libs")

- dry_run:

  If TRUE, only report what would be removed, without deleting anything

## Value

Character vector of the pruned (or, if \`dry_run\`, prunable) directory
names, invisibly

## Details

The libraries managed by \[setup_external_libraries()\] (Bootstrap, Font
Awesome, Academicons) and the package's own JavaScript, copied by
\[copy_package_javascript()\] into \`docs/libs/codecheck\`, are always
kept, since their presence is intentional regardless of whether the
current HTML output happens to link to every file inside them.

\*\*This must only be run after a complete, unfiltered render.\*\* A
partial render (a \`from\`/\`to\` subset, or one with certificate
failures) leaves HTML files un-rerendered that may still reference a
directory this would otherwise delete. As a further safeguard, if no
HTML file can be found under \`docs_dir\` at all, nothing is deleted -
an empty result there means there is no reliable way to tell what is
still referenced, not that everything is unreferenced.

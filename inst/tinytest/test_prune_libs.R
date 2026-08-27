# Tests for prune_libs() (codecheckers/codecheck#89): removing docs/libs
# directories no rendered HTML file references any more.

if (!requireNamespace("codecheck", quietly = TRUE)) {
  exit_file("Package not installed properly")
}

specs <- codecheck:::external_library_specs()

# Every managed library directory name (the first path component of every one
# of its expected files), e.g. "bootstrap", "font-awesome", "academicons".
# font-awesome and academicons nest their files one level deeper
# ("font-awesome/css/font-awesome.min.css"), which is what a naive
# dirname(files[[1]]) computation gets wrong (it would return
# "font-awesome/css" instead of "font-awesome") - the bug this suite guards
# against actually deleted these directories from a real render.
managed_dirs <- unique(vapply(specs, function(lib) {
  strsplit(codecheck:::library_expected_files(lib)[[1]], "/", fixed = TRUE)[[1]][1]
}, character(1)))

# Build a docs/ tree with a libs dir containing every managed library
# directory (including the nested font-awesome/academicons cases and the
# separately-managed "codecheck" JS directory), plus a couple of
# unreferenced/referenced version-named ones, and one HTML file that
# references the managed libraries the way the real templates do (nested
# href, see inst/extdata/templates/general/index_header_template.html) plus
# one of the version-named ones.
make_docs_tree <- function() {
  docs_dir <- tempfile("docs")
  libs_dir <- file.path(docs_dir, "libs")

  for (lib in specs) {
    for (file in codecheck:::library_expected_files(lib)) {
      path <- file.path(libs_dir, file)
      dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
      writeLines("x", path)
    }
  }
  dir.create(file.path(libs_dir, "codecheck"), recursive = TRUE)
  writeLines("x", file.path(libs_dir, "codecheck", "citation.min.js"))

  dir.create(file.path(libs_dir, "header-attrs-2.29"), recursive = TRUE)
  writeLines("x", file.path(libs_dir, "header-attrs-2.29", "header-attrs.js"))

  dir.create(file.path(libs_dir, "header-attrs-2.31"), recursive = TRUE)
  writeLines("x", file.path(libs_dir, "header-attrs-2.31", "header-attrs.js"))

  writeLines(
    c("<html><head>",
      '<link rel="stylesheet" href="libs/academicons/css/academicons.min.css">',
      '<link rel="stylesheet" href="libs/font-awesome/css/font-awesome.min.css">',
      '<link rel="stylesheet" href="libs/bootstrap/bootstrap.min.css">',
      '<script src="libs/codecheck/citation.min.js"></script>',
      '<script src="libs/header-attrs-2.31/header-attrs.js"></script>',
      "</head><body></body></html>"),
    file.path(docs_dir, "index.html")
  )

  docs_dir
}

# Test 1: an unreferenced, unmanaged directory is removed; every managed
# directory and the referenced version-named one survive
docs_dir <- make_docs_tree()
libs_dir <- file.path(docs_dir, "libs")

removed <- prune_libs(docs_dir = docs_dir, libs_dir = libs_dir)

expect_equal(removed, "header-attrs-2.29",
            info = "only the unreferenced directory is reported as pruned")
expect_false(dir.exists(file.path(libs_dir, "header-attrs-2.29")),
            info = "the unreferenced directory is deleted")
expect_true(dir.exists(file.path(libs_dir, "header-attrs-2.31")),
           info = "a directory referenced by an HTML file survives")
for (managed_dir in managed_dirs) {
  expect_true(dir.exists(file.path(libs_dir, managed_dir)),
             info = paste("managed library directory survives:", managed_dir))
}
expect_true(dir.exists(file.path(libs_dir, "codecheck")),
           info = "the codecheck JS directory always survives")

# Test 1b: a managed, nested-path library (font-awesome/academicons) survives
# even when nothing currently references it - this is the exact scenario the
# original bug got wrong (it deleted these unconditionally, not just when
# unreferenced)
docs_dir <- tempfile("docs")
libs_dir <- file.path(docs_dir, "libs")
for (lib in specs) {
  for (file in codecheck:::library_expected_files(lib)) {
    path <- file.path(libs_dir, file)
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    writeLines("x", path)
  }
}
dir.create(file.path(libs_dir, "codecheck"), recursive = TRUE)
writeLines("x", file.path(libs_dir, "codecheck", "citation.min.js"))
writeLines("<html><head></head><body>no library references at all</body></html>",
          file.path(docs_dir, "index.html"))

removed <- prune_libs(docs_dir = docs_dir, libs_dir = libs_dir)
expect_equal(removed, character(0),
            info = "managed libraries are never pruned, even when no HTML currently references them")
for (managed_dir in c(managed_dirs, "codecheck")) {
  expect_true(dir.exists(file.path(libs_dir, managed_dir)),
             info = paste("managed directory survives with zero references:", managed_dir))
}

# Test 2: dry_run reports without deleting anything
docs_dir <- make_docs_tree()
libs_dir <- file.path(docs_dir, "libs")

removed <- prune_libs(docs_dir = docs_dir, libs_dir = libs_dir, dry_run = TRUE)

expect_equal(removed, "header-attrs-2.29",
            info = "dry_run reports the same directories that a real run would prune")
expect_true(dir.exists(file.path(libs_dir, "header-attrs-2.29")),
           info = "dry_run does not actually delete anything")

# Test 3: nothing to prune when every directory is referenced or managed
docs_dir <- make_docs_tree()
libs_dir <- file.path(docs_dir, "libs")
unlink(file.path(libs_dir, "header-attrs-2.29"), recursive = TRUE)

removed <- prune_libs(docs_dir = docs_dir, libs_dir = libs_dir)

expect_equal(removed, character(0),
            info = "nothing is pruned when all remaining directories are referenced or managed")

# Test 4: a missing libs directory is a no-op, not an error
removed <- prune_libs(docs_dir = tempfile(), libs_dir = tempfile())
expect_equal(removed, character(0),
            info = "a missing libraries directory prunes nothing and does not error")

# Test 5: no HTML files at all is a no-op, not "everything is unreferenced"
docs_dir <- tempfile("docs")
libs_dir <- file.path(docs_dir, "libs")
dir.create(file.path(libs_dir, "header-attrs-2.29"), recursive = TRUE)
writeLines("x", file.path(libs_dir, "header-attrs-2.29", "header-attrs.js"))

removed <- prune_libs(docs_dir = docs_dir, libs_dir = libs_dir)
expect_equal(removed, character(0),
            info = "no HTML files under docs_dir means nothing is pruned, for safety")
expect_true(dir.exists(file.path(libs_dir, "header-attrs-2.29")),
           info = "without any HTML to check references against, directories are left alone")

# Tests for is_full_register_run() - whether register_render()'s from/to gates
# prune_libs(). register_render() subsets via register[(from:to),], which
# accepts from/to in either direction (oldest-first or newest-first, as
# register_check() also supports, see codecheckers/codecheck#79), so a full
# run can be either from=1,to=n or from=n,to=1.
expect_true(codecheck:::is_full_register_run(1, 10, 10),
           info = "oldest-first full range (from=1, to=n) is a full run")
expect_true(codecheck:::is_full_register_run(10, 1, 10),
           info = "newest-first full range (from=n, to=1) is also a full run")
expect_true(codecheck:::is_full_register_run(1, 1, 1),
           info = "a single-row register is a full run either way")
expect_false(codecheck:::is_full_register_run(3, 5, 10),
            info = "a subset in the middle is not a full run")
expect_false(codecheck:::is_full_register_run(1, 9, 10),
            info = "oldest-first missing the last row is not a full run")
expect_false(codecheck:::is_full_register_run(10, 2, 10),
            info = "newest-first missing the last row is not a full run")

out <- tempfile("rules-pages")
pages <- generate_rules_pages(output_dir = out, rules_dir = tempdir())

expect_true(file.exists(file.path(out, "rules", "1.0", "index.html")))
expect_true(file.exists(file.path(out, "rules", "2.0", "index.html")))
expect_false(file.exists(file.path(out, "rules", "index.html")),
             info = "no listing page: direct URL only")

html <- paste(readLines(file.path(out, "rules", "2.0", "index.html")), collapse = "\n")
expect_true(grepl('<meta name="robots" content="noindex">', html, fixed = TRUE))
for (id in codecheck_rules("2.0")$id) {
  expect_true(grepl(paste0('id="', id, '"'), html, fixed = TRUE), info = id)
}
expect_true(grepl("rules-deprecated", html, fixed = TRUE) ==
              any(codecheck_rules("2.0")$status == "deprecated"))
expect_true(grepl("superseded by", paste(readLines(file.path(out, "rules", "1.0", "index.html")), collapse = "\n")))

unlink(out, recursive = TRUE)

tinytest::using(ttdo)

config_path <- system.file("extdata", "config.R", package = "codecheck")
if (config_path == "" || !file.exists(config_path)) {
  exit_file("Package not installed properly")
}
source(config_path)

metadata <- list(
  timestamp = "2026-08-13 12:00:00 CEST",
  package_version = "0.25.0",
  register_commit_short = "abc1234",
  register_commit_url = "https://github.com/codecheckers/register/commit/abc1234"
)

build_info <- codecheck::generate_footer_build_info(metadata)

# the build info contains a commit link, so the templates must interpolate it
# unescaped ({{{ }}}), otherwise the anchor shows up as literal text in the footer
expect_true(grepl('<a href="https://github.com/codecheckers/register/commit/abc1234">abc1234</a>',
                  build_info, fixed = TRUE))

for (template in c("reg_tables", "non_reg_tables", "cert")) {
  path <- system.file("extdata", "templates", template,
                      "index_postfix_template.html", package = "codecheck")
  rendered <- whisker::whisker.render(
    paste(readLines(path, warn = FALSE), collapse = "\n"),
    list(build_info = build_info)
  )
  expect_false(grepl("&lt;a href=", rendered, fixed = TRUE),
               info = paste("escaped anchor in", template, "postfix template"))
  expect_true(grepl(">abc1234</a>", rendered, fixed = TRUE),
              info = paste("no commit link in", template, "postfix template"))
}

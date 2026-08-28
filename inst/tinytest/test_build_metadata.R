# The <meta name="generator"> tag content: package version only, no commit
# hash (register pages), see generate_meta_generator_content().

library(codecheck)

expect_equal(
  generate_meta_generator_content(list(package_version = "0.27.0")),
  "codecheck 0.27.0"
)

# commit info present in the metadata (as get_build_metadata() would supply
# it) must not leak into the generator tag
expect_equal(
  generate_meta_generator_content(list(
    package_version = "0.27.0",
    register_commit_short = "abc1234",
    register_commit_url = "https://github.com/codecheckers/register/commit/abc1234",
    codecheck_commit_short = "def5678",
    codecheck_commit_url = "https://github.com/codecheckers/codecheck/commit/def5678"
  )),
  "codecheck 0.27.0"
)

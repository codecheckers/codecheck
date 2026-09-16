# Choosing the specification version: declared, then dated, then newest.
# The Go bot does the same, see internal/check/run.go SpecVersion.
library(codecheck)

# The historical URL names a version even though the page 404s.
expect_equal(
  codecheck_spec_version(list(version = "https://codecheck.org.uk/spec/1.0")),
  "1.0"
)
expect_equal(
  codecheck_spec_version(list(version = "https://codecheck.org.uk/spec/config/2.0")),
  "2.0"
)

# ... but it is still not a published URL, which is what CC-CFG-015 reports.
expect_true(is.na(codecheck:::spec_version_from_url("https://codecheck.org.uk/spec/1.0")))

# A file with no version node is judged by when it was checked.
expect_equal(codecheck_spec_version(list(check_time = "2019-02-14 10:00:00")), "1.0")
expect_equal(codecheck_spec_version(list(check_time = "2021-06-01")), "1.0")
expect_equal(codecheck_spec_version(list(check_time = "2026-09-30")), "2.0")

# ... or by when it was last changed, when it says nothing itself.
expect_equal(codecheck_spec_version(list(), modified = as.Date("2021-03-01")), "1.0")

# ... and only an undatable file is assumed to follow the newest.
expect_equal(codecheck_spec_version(list()), codecheck_spec_versions()[1])

tinytest::using(ttdo)

source("mocks.R")
source(system.file("extdata", "config.R", package = "codecheck"))

entry <- data.frame(Certificate = "2024-111", stringsAsFactors = FALSE)

# capture cli_alert_info(), which goes through message()
capture_info <- function(expr) {
  paste(capture.output(force(expr), type = "message"), collapse = "\n")
}

# --- check_repository_org(): pure string check, no mocking needed --------

# Test 1: GitHub repo in codecheckers/ is fine
expect_silent(
  codecheck:::check_repository_org(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
)

# Test 2: GitHub repo in a sub-path is still resolved to its org
expect_silent(
  codecheck:::check_repository_org(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo|reports"))
)

# Test 3: GitHub repo outside codecheckers/ fails
expect_error(
  codecheck:::check_repository_org(entry, codecheck:::parse_repository_spec("github::someoneelse/Foo")),
  pattern = "codecheckers"
)

# Test 3b: additional allowed GitHub org from CONFIG$ALLOWED_REPO_ORGS is fine
expect_silent(
  codecheck:::check_repository_org(entry, codecheck:::parse_repository_spec("github::reproducible-agile/reviews-2025|reports/28"))
)

# Test 4: GitLab repo in cdchck/ is fine
expect_silent(
  codecheck:::check_repository_org(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
)

# Test 5: GitLab repo outside cdchck/ fails
expect_error(
  codecheck:::check_repository_org(entry, codecheck:::parse_repository_spec("gitlab::othergroup/Foo")),
  pattern = "cdchck"
)

# Test 6: platforms without an org concept are not checked
expect_silent(
  codecheck:::check_repository_org(entry, codecheck:::parse_repository_spec("osf::ABC12"))
)
expect_silent(
  codecheck:::check_repository_org(entry, codecheck:::parse_repository_spec("zenodo::123"))
)

# --- check_repository_archived(): warning, mocked GitHub + GitLab --------

# Test 7: GitHub, archived
expect_silent(
  with_mocked_codecheck(
    list(get_github_repo_metadata = function(repo) list(archived = TRUE)),
    codecheck:::check_repository_archived(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)

# Test 8: GitHub, not archived
expect_warning(
  with_mocked_codecheck(
    list(get_github_repo_metadata = function(repo) list(archived = FALSE)),
    codecheck:::check_repository_archived(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  ),
  pattern = "not archived"
)

# Test 9: GitLab, archived
expect_silent(
  with_mocked_codecheck(
    list(get_gitlab_project_metadata = function(repo) list(archived = TRUE)),
    codecheck:::check_repository_archived(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
  )
)

# Test 10: GitLab, not archived
expect_warning(
  with_mocked_codecheck(
    list(get_gitlab_project_metadata = function(repo) list(archived = FALSE)),
    codecheck:::check_repository_archived(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
  ),
  pattern = "not archived"
)

# Test 11: metadata lookup failure degrades to a no-op, not a crash
expect_silent(
  with_mocked_codecheck(
    list(get_github_repo_metadata = function(repo) NULL),
    codecheck:::check_repository_archived(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)

# --- check_repository_badge(): info only, mocked GitHub + GitLab ---------

# Test 12: GitHub README with a badge -> no info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_github_readme_raw = function(repo) "[![CODECHECK](https://codecheck.org.uk/img/codeworks-badge.svg)](...)"),
    codecheck:::check_repository_badge(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)
expect_equal(info, "")

# Test 13: GitHub README without a badge -> info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_github_readme_raw = function(repo) "# Foo\n\nJust a plain repository README."),
    codecheck:::check_repository_badge(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)
expect_true(grepl("does not yet have a CODECHECK badge", info))

# Test 14: GitLab README with a badge -> no info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_gitlab_readme_raw = function(repo) "See the codecheck-badge.svg in this repo."),
    codecheck:::check_repository_badge(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
  )
)
expect_equal(info, "")

# Test 15: GitLab README without a badge -> info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_gitlab_readme_raw = function(repo) "# Foo"),
    codecheck:::check_repository_badge(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
  )
)
expect_true(grepl("does not yet have a CODECHECK badge", info))

# Test 16: missing README is a no-op
info <- capture_info(
  with_mocked_codecheck(
    list(get_github_readme_raw = function(repo) NULL),
    codecheck:::check_repository_badge(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)
expect_equal(info, "")

# --- check_repository_license(): info only, mocked GitHub + GitLab -------

# Test 17: GitHub, license present -> no info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_github_repo_metadata = function(repo) list(license = list(key = "mit"))),
    codecheck:::check_repository_license(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)
expect_equal(info, "")

# Test 18: GitHub, no license -> info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_github_repo_metadata = function(repo) list(license = NULL)),
    codecheck:::check_repository_license(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)
expect_true(grepl("has no license", info))

# Test 19: GitLab, license present -> no info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_gitlab_project_metadata = function(repo) list(license = list(key = "mit"))),
    codecheck:::check_repository_license(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
  )
)
expect_equal(info, "")

# Test 20: GitLab, no license -> info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_gitlab_project_metadata = function(repo) list(license = NULL)),
    codecheck:::check_repository_license(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
  )
)
expect_true(grepl("has no license", info))

# --- check_repository_topic(): info only, mocked GitHub + GitLab ---------

# Test 21: GitHub, 'codecheck' topic present -> no info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_github_repo_metadata = function(repo) list(topics = list("codecheck", "reproducibility"))),
    codecheck:::check_repository_topic(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)
expect_equal(info, "")

# Test 22: GitHub, no 'codecheck' topic -> info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_github_repo_metadata = function(repo) list(topics = list("reproducibility"))),
    codecheck:::check_repository_topic(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)
expect_true(grepl("does not have the 'codecheck' topic tag", info))

# Test 23: GitLab, 'codecheck' topic present -> no info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_gitlab_project_metadata = function(repo) list(topics = list("codecheck"))),
    codecheck:::check_repository_topic(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
  )
)
expect_equal(info, "")

# Test 24: GitLab, no topics at all -> info message
info <- capture_info(
  with_mocked_codecheck(
    list(get_gitlab_project_metadata = function(repo) list(topics = NULL)),
    codecheck:::check_repository_topic(entry, codecheck:::parse_repository_spec("gitlab::cdchck/Foo"))
  )
)
expect_true(grepl("does not have the 'codecheck' topic tag", info))

# Test 25: metadata lookup failure degrades to a no-op, not a crash
expect_silent(
  with_mocked_codecheck(
    list(get_github_repo_metadata = function(repo) NULL),
    codecheck:::check_repository_topic(entry, codecheck:::parse_repository_spec("github::codecheckers/Foo"))
  )
)

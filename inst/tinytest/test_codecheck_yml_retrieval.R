tinytest::using(ttdo)

# Invalid or unsupported ----
expect_error(get_codecheck_yml("unsupported::repo/spec"),
             pattern = "Unsupported repository type 'unsupported")
expect_error(get_codecheck_yml("github::not_org_and_repo"),
             pattern = "Incomplete repo specification for type 'github'(.*)'not_org_and_repo'")

expect_warning(get_codecheck_yml("github::codecheckers/register"),
               pattern = "codecheck.yml not found (.*)codecheckers/register")
expect_warning(get_codecheck_yml("osf::6K5FH"),
               pattern = "codecheck.yml not found (.*)https://osf.io/6K5FH")
expect_warning(get_codecheck_yml("gitlab::nuest/sensebox-binder"),
               pattern = "codecheck.yml not found (.*)nuest/sensebox-binder")

# GitHub ----
expect_silent({ piccolo <- get_codecheck_yml("github::codecheckers/Piccolo-2020") })
expect_equal(piccolo$report, "http://doi.org/10.5281/zenodo.3674056")

# OSF ----
expect_silent({ agile <- get_codecheck_yml("osf::5SVMT") })
expect_equal(agile$report, "https://doi.org/10.17605/OSF.IO/5SVMT")

# GitLab.com ----
expect_silent({ gigabyte <- get_codecheck_yml("gitlab::cdchck/community-codechecks/2022-svaRetro-svaNUMT") })
expect_equal(gigabyte$report, "https://doi.org/10.5281/zenodo.7084333")

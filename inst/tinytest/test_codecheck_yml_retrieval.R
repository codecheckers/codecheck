tinytest::using(ttdo)

# Invalid or unsupported ----
expect_error(get_codecheck_yml("unsupported::repo/spec"),
             pattern = "Unsupported repository type 'unsupported")
expect_error(get_codecheck_yml("github::not_org_and_repo"),
             pattern = "Incomplete repo specification for type 'github'(.*)'not_org_and_repo'")

expect_warning(get_codecheck_yml("github::codecheckers/register"),
               pattern = "codecheck.yml not found in(.*)codecheckers/register")
expect_warning(get_codecheck_yml("osf::6K5FH"),
               pattern = "codecheck.yml not found in(.*)https://osf.io/6K5FH")

# GitHub ----
expect_silent({ piccolo <- get_codecheck_yml("github::codecheckers/Piccolo-2020") })
expect_equal(piccolo$report, "http://doi.org/10.5281/zenodo.3674056")

# OSF ----
expect_silent({ agile <- get_codecheck_yml("osf::5SVMT") })
expect_equal(agile$report, "https://doi.org/10.17605/OSF.IO/5SVMT")

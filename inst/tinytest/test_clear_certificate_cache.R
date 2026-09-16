# Tests for register_clear_cache(certificates = ...), which refreshes what is
# cached about some certificates and keeps the rest of the cache

library(codecheck)
source("mocks.R")

# Never against the user's real cache, see test_register_check.R
old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(tempfile("codecheck_cache"))

register <- data.frame(
  Certificate = c("2025-009", "2025-010"),
  Repository = c("osf::gv2z4", "osf::fxkws"),
  Type = "conference", Venue = "AGILEGIS", Issue = 147,
  stringsAsFactors = FALSE)

config_for <- function(orcid, report, title = "Mobility Vitality",
                       reference = "https://doi.org/10.5194/agile-giss-6-1-2025") {
  list(paper = list(title = title,
                    authors = list(list(name = "Grant McKenzie", ORCID = orcid)),
                    reference = reference),
       report = report)
}
old_config <- config_for("0000-0003-3247-7777", "https://doi.org/10.5281/zenodo.1234567")
new_config <- config_for("0000-0003-3247-2777", "https://doi.org/10.5281/zenodo.1234567")
other_config <- config_for("0000-0002-1825-0097", "https://doi.org/10.17605/OSF.IO/fxkws",
                           title = "Urban density", reference = "https://doi.org/10.5194/agile-giss-6-2-2025")

store <- function(key, dirs) {
  R.cache::saveCache(list(status = "found", value = "cached"), key = key, dirs = dirs)
}
is_cached <- function(key, dirs) {
  path <- R.cache::findCache(key = key, dirs = dirs)
  !is.null(path) && file.exists(path)
}

# What a render of both certificates leaves in the cache
openalex_key <- function(config) {
  list("openalex_id", config$paper$reference, config$paper$title,
       config$paper$authors[[1]]$name)
}
for (cert in c("2025-009", "2025-010")) {
  repository <- register$Repository[register$Certificate == cert]
  config <- if (cert == "2025-009") old_config else other_config
  store(list("abstract", repository), c("codecheck", "abstract"))
  store(openalex_key(config), c("codecheck", "openalex_id"))
  store(list(report_link = config$report, cert_id = cert), c("codecheck", "cert_link"))
  store(list(report_url = config$report), c("codecheck", "report_platform"))
}
store(list(record_id = 1234567L), "zenodo-policy")
store(list("orcid_affiliations", "0000-0003-3247-7777"), c("codecheck", "orcid_affiliations"))

refetched <- character(0)
removed <- with_mocked_codecheck(
  list(get_codecheck_yml = function(x) if (x == "osf::gv2z4") old_config else other_config,
       get_codecheck_yml_cached = function(x, force = FALSE) {
         refetched <<- c(refetched, paste(x, force))
         if (x == "osf::gv2z4") new_config else other_config
       }),
  suppressMessages(register_clear_cache("2025-009", register = register)))

expect_equal(refetched, "osf::gv2z4 TRUE",
             info = "only the named certificate's codecheck.yml is fetched again, forced")
expect_equal(removed, 5)
expect_false(is_cached(list("abstract", "osf::gv2z4"), c("codecheck", "abstract")))
expect_false(is_cached(openalex_key(old_config), c("codecheck", "openalex_id")))
expect_false(is_cached(list(report_link = old_config$report, cert_id = "2025-009"),
                       c("codecheck", "cert_link")))
expect_false(is_cached(list(report_url = old_config$report), c("codecheck", "report_platform")))
expect_false(is_cached(list(record_id = 1234567L), "zenodo-policy"))

# The other certificate and the per-person entries are untouched.
expect_true(is_cached(list("abstract", "osf::fxkws"), c("codecheck", "abstract")))
expect_true(is_cached(openalex_key(other_config), c("codecheck", "openalex_id")))
expect_true(is_cached(list(report_url = other_config$report), c("codecheck", "report_platform")))
expect_true(is_cached(list("orcid_affiliations", "0000-0003-3247-7777"),
                      c("codecheck", "orcid_affiliations")))

expect_error(register_clear_cache("2099-001", register = register),
             pattern = "Not in the register: 2099-001")

unlink(R.cache::getCacheRootPath(), recursive = TRUE)
R.cache::setCacheRootPath(old_root)

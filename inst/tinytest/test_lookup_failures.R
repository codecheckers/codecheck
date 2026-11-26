# A lookup of a remote resource that fails is recorded, and register_render()
# fails at its end when there are any, so that CI does not commit a render
# that lacks data the previous one had (codecheckers/register#247). Successful
# lookups are cached as before, failed ones are not, so a second try asks only
# for those.

library(codecheck)
source(system.file("extdata", "config.R", package = "codecheck"))

# Nothing is recorded outside a render
Sys.unsetenv("CODECHECK_LOOKUP_FAILURES")
expect_silent(codecheck:::record_lookup_failure("anything"))

# the record is read when it is stopped, so these read a copy of it
recorded <- function(path) unique(readLines(path, warn = FALSE))
path <- codecheck:::start_lookup_failures()
expect_equal(recorded(path), character(0))
codecheck:::record_lookup_failure("codecheck.yml of 2020-020 (osf::7TWR2)")
codecheck:::record_lookup_failure("codecheck.yml of 2020-020 (osf::7TWR2)")
codecheck:::record_lookup_failure("a message\nover two lines")
expect_equal(recorded(path),
             c("codecheck.yml of 2020-020 (osf::7TWR2)", "a message over two lines"))

# A request a service cannot answer for now is recorded, at the HTTP layer: a
# server error, a rate limit, a timeout or no connection. An answer - a 404 -
# is not, it would be the same next time and fail every render.
source("mocks.R")
expect_true(codecheck:::is_outage_status(503L))
expect_true(codecheck:::is_outage_status(429L))
expect_false(codecheck:::is_outage_status(404L))
expect_false(codecheck:::is_outage_status(200L))

# Only the services the register depends on count: any other site may answer
# 429 or 5xx to every script for good, as UNESCO's IIEP does
expect_true(codecheck:::is_core_service("https://api.osf.io/v2/nodes/6ngyc/"))
expect_true(codecheck:::is_core_service("https://zenodo.org/api/records/1"))
expect_true(codecheck:::is_core_service("https://raw.githubusercontent.com/codecheckers/x/main/a.csv"))
expect_false(codecheck:::is_core_service("http://www.iiep.unesco.org/en/publication/x"))
expect_false(codecheck:::is_core_service("https://notzenodo.org/"))
expect_false(codecheck:::is_core_service("not a url"))
# no connection: nothing listens on port 9 of this machine, which is no
# service the register depends on
expect_error(codecheck:::codecheck_GET("http://127.0.0.1:9/", timeout_seconds = 5))
expect_false(any(startsWith(recorded(path), "http://127.0.0.1:9/")))

# a retry records the outcome, not the attempts a later one makes good
answers <- c(503L, 200L)
with_mocked_codecheck(list(codecheck_GET = function(url, ..., record_outage = TRUE) {
  status <- answers[1]; answers <<- answers[-1]; mock_response(url, status)
}), {
  expect_equal(httr::status_code(codecheck:::codecheck_GET_retry("https://api.zenodo.org/one", max_wait = 1)), 200L)
})
expect_false(any(grepl("api.zenodo.org/one", recorded(path), fixed = TRUE)))
with_mocked_codecheck(list(codecheck_GET = function(url, ..., record_outage = TRUE) mock_response(url, 503L)), {
  codecheck:::codecheck_GET_retry("https://api.zenodo.org/two", max_attempts = 2, max_wait = 1)
})
expect_true(any(startsWith(recorded(path), "https://api.zenodo.org/two - HTTP 503")))
with_mocked_codecheck(list(codecheck_GET = function(url, ..., record_outage = TRUE) mock_response(url, 404L)), {
  codecheck:::codecheck_GET_retry("https://api.zenodo.org/three", max_attempts = 2, max_wait = 1)
})
expect_false(any(grepl("api.zenodo.org/three", recorded(path), fixed = TRUE)))

# The clients that do their own HTTP report an outage only as an error message;
# a status counts only where it is one
outage <- function(message) codecheck:::is_outage_error(simpleError(message))
expect_true(outage("OSF request failed after 4 attempts: lexical error: invalid char in json text. <html>"))
expect_true(outage("GitHub API error (503): Service Unavailable"))
expect_true(outage("API rate limit exceeded for 1.2.3.4"))
expect_true(outage("Timeout was reached: [api.github.com] Operation timed out after 10001 milliseconds"))
expect_true(outage("Zenodo answered HTTP 502 for the codecheck.yml of record 1"))
expect_false(outage("GitHub API error (404): Not Found: /repos/org/model-500/contents/codecheck.yml"))
expect_false(outage("Scanner error: mapping values are not allowed in this context at line 512"))
expect_false(outage("OSF request failed after 4 attempts: Requested resource is not available"))
expect_false(outage("Could not resolve host: expired.example"))
expect_true(outage("Could not resolve host: api.github.com"))
expect_true(outage("Empty reply from server"))
expect_false(outage("SSL certificate problem: certificate has expired"))
expect_false(outage("Unsupported repository specification: githb::org/repo"))

# A lookup records the outages its requests hit only if it ends without a
# value: a DOI lookup answering 502 is no loss when the title search finds it
codecheck:::collect_outages({ codecheck:::note_outage("recovered - HTTP 502"); "W1" },
                            failed = function(value) is.na(value))
expect_false("recovered - HTTP 502" %in% recorded(path))
codecheck:::collect_outages({ codecheck:::note_outage("lost - HTTP 502"); NA },
                            failed = function(value) is.na(value))
expect_true("lost - HTTP 502" %in% recorded(path))
expect_error(codecheck:::collect_outages({ codecheck:::note_outage("raised - HTTP 503"); stop("gone") }), "gone")
expect_true("raised - HTTP 503" %in% recorded(path))
# a lookup inside another passes its outages to it, which may still recover
codecheck:::collect_outages(failed = function(value) is.na(value), {
  codecheck:::collect_outages({ codecheck:::note_outage("inner - HTTP 503"); NA },
                              failed = function(value) is.na(value))
  "found by the fallback"
})
expect_false("inner - HTTP 503" %in% recorded(path))
# an interrupted lookup leaves no scope behind
try(codecheck:::collect_outages(stop("interrupted")), silent = TRUE)
expect_equal(length(codecheck:::outage_scopes$stack), 0L)
# without an outage a failed lookup is an answer, and is not recorded
before <- recorded(path)
codecheck:::collect_outages(NA, failed = function(value) is.na(value))
expect_equal(recorded(path), before)
# the shared cache runs its lookups in such a scope
cache_root <- tempfile("cache")
dir.create(cache_root)
old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(cache_root)
codecheck:::cached_lookup_result(list("one"), c("codecheck", "test_scope"), function() {
  codecheck:::note_outage("cached recovered - HTTP 503"); list(status = "found", value = "W1")
})
codecheck:::cached_lookup_result(list("two"), c("codecheck", "test_scope"), function() {
  codecheck:::note_outage("cached lost - HTTP 503"); list(status = "failed", value = NULL)
})
# a field whose previous value resolve_external_field() keeps loses nothing
codecheck:::cached_lookup_result(list("three"), c("codecheck", "test_scope"), counts = FALSE, function() {
  codecheck:::note_outage("cached kept - HTTP 503"); list(status = "failed", value = NULL)
})
R.cache::setCacheRootPath(old_root)
expect_false("cached recovered - HTTP 503" %in% recorded(path))
expect_true("cached lost - HTTP 503" %in% recorded(path))
expect_false("cached kept - HTTP 503" %in% recorded(path))

# The prefetch of the certificate links drops its failures: the link is
# resolved again, and counted, where it is used
source(system.file("extdata", "config.R", package = "codecheck"))
with_mocked_codecheck(list(get_cert_link = function(report, cert_id) {
  codecheck:::note_outage(paste("prefetch", cert_id, "- HTTP 503")); NULL
}), {
  codecheck:::prefetch_cert_links(data.frame(Report = "https://doi.org/10.5281/zenodo.1",
                                             Certificate = "2020-001", stringsAsFactors = FALSE))
})
expect_false("prefetch 2020-001 - HTTP 503" %in% recorded(path))

# An outage the HTTP layer noted is not listed a second time by the yml fetch
with_mocked_codecheck(list(get_codecheck_yml_cached = function(x) {
  codecheck:::note_outage("https://gitlab.com/cdchck/x - HTTP 503 after 4 attempts")
  codecheck:::stop_noted_outage("GitLab answered 503 for https://gitlab.com/cdchck/x")
}), {
  expect_error(get_codecheck_yml("gitlab::cdchck/x"), "GitLab answered 503")
})
expect_false(any(grepl("codecheck.yml from gitlab::cdchck/x", recorded(path), fixed = TRUE)))
expect_true("https://gitlab.com/cdchck/x - HTTP 503 after 4 attempts" %in% recorded(path))

# A codechecker list that cannot be fetched counts only without a cached copy
cache_root <- tempfile("cache")
dir.create(cache_root)
old_root <- R.cache::getCacheRootPath()
R.cache::setCacheRootPath(cache_root)
down <- function(url) { codecheck:::note_outage(paste(url, "- HTTP 503")); NULL }
suppressWarnings(codecheck:::fetch_codechecker_list("https://raw.example/uncached.csv", refresh = TRUE, fetch = down))
expect_true("https://raw.example/uncached.csv - HTTP 503" %in% recorded(path))
R.cache::saveCache(data.frame(name = "A"), key = list("https://raw.example/cached.csv"),
                   dirs = codecheck:::CODECHECKER_LIST_CACHE_DIRS)
suppressWarnings(codecheck:::fetch_codechecker_list("https://raw.example/cached.csv", refresh = TRUE, fetch = down))
expect_false(any(grepl("raw.example/cached.csv", recorded(path), fixed = TRUE)))
R.cache::setCacheRootPath(old_root)

# zen4R answers NULL for a record it could not read; asking Zenodo tells an
# outage from a record that is not there
with_mocked_codecheck(list(zenodo_record = function(x, sandbox = FALSE) NULL,
                           codecheck_GET_retry = function(url, ...) mock_response(url, 503L)), {
  expect_error(codecheck:::get_codecheck_yml_zenodo("1234"), "Zenodo could not be asked for record 1234: HTTP 503")
})
with_mocked_codecheck(list(zenodo_record = function(x, sandbox = FALSE) NULL,
                           codecheck_GET_retry = function(url, ...) mock_response(url, 404L)), {
  expect_warning(none <- codecheck:::get_codecheck_yml_zenodo("1234"), "not found")
})
expect_null(none)
# Zenodo recovered by the time it is asked: the record is read from its answer
with_mocked_codecheck(list(zenodo_record = function(x, sandbox = FALSE) NULL,
                           codecheck_GET_retry = function(url, ...) {
                             if (grepl("/api/records/", url, fixed = TRUE)) {
                               return(mock_json_response(url, list(files = list(list(
                                 key = "codecheck.yml", links = list(self = "https://zenodo.org/f/codecheck.yml"))))))
                             }
                             structure(list(url = url, status_code = 200L,
                                            headers = structure(list(`content-type` = "text/yaml"), class = c("insensitive", "list")),
                                            content = charToRaw("certificate: 2020-001\n")), class = "response")
                           }), {
  recovered <- codecheck:::get_codecheck_yml_zenodo("1234")
})
expect_equal(recovered$certificate, "2020-001")

# An API key is not printed with a recorded URL
codecheck:::record_lookup_failure("https://api.openalex.org/works/W1?select=id&api_key=s3cr3t - HTTP 503")
expect_true("https://api.openalex.org/works/W1?select=id&api_key=*** - HTTP 503" %in% recorded(path))
expect_false(any(grepl("s3cr3t", recorded(path), fixed = TRUE)))

# A failed fetch of a codecheck.yml is recorded, also where a step of the render
# calls get_codecheck_yml() itself
with_mocked_codecheck(list(get_codecheck_yml_cached = function(x) stop("OSF request failed after 4 attempts: HTTP 502")), {
  expect_warning(codecheck:::get_codecheck_yml_or_null("osf::7TWR2", "2020-020"), "Could not retrieve")
  expect_error(get_codecheck_yml("osf::AAAAA"), "OSF request failed")
})
expect_true(all(c("codecheck.yml from osf::7TWR2", "codecheck.yml from osf::AAAAA") %in%
                  sub(" - .*", "", recorded(path))))
# a repository that is gone is an answer, and is not recorded
with_mocked_codecheck(list(get_codecheck_yml_cached = function(x) stop("GitHub API error (404): Not Found")), {
  expect_error(get_codecheck_yml("github::codecheckers/renamed"), "404")
})
expect_false(any(grepl("renamed", recorded(path), fixed = TRUE)))

# GitLab answering 5xx is an outage, not a repository without a codecheck.yml
with_mocked_codecheck(list(codecheck_GET = function(url, ...) mock_response(url, 503L)), {
  expect_error(codecheck:::get_codecheck_yml_gitlab("cdchck/x"), "GitLab answered 503")
})
with_mocked_codecheck(list(codecheck_GET = function(url, ...) mock_response(url, 404L)), {
  expect_warning(missing_yml <- codecheck:::get_codecheck_yml_gitlab("cdchck/x"), "not found")
})
expect_null(missing_yml)

# Workers of a parallel render add to the same record
if (.Platform$OS.type != "windows") {
  invisible(parallel::mclapply(1:2, function(i) codecheck:::record_lookup_failure(paste("worker", i)),
                               mc.cores = 2))
  expect_true(all(c("worker 1", "worker 2") %in% recorded(path)))
}

expect_true("worker 1" %in% codecheck:::stop_lookup_failures(path) || .Platform$OS.type == "windows")
expect_false(file.exists(path))
expect_equal(Sys.getenv("CODECHECK_LOOKUP_FAILURES"), "")
expect_equal(codecheck:::stop_lookup_failures(path), character(0), info = "a second stop, as on.exit does")

# The render fails with what could not be looked up, at most ten of them named
expect_silent(codecheck:::stop_on_lookup_failures(character(0)))
captured <- capture_messages(codecheck:::stop_on_lookup_failures(
  c("codecheck.yml of 2020-020 (osf::7TWR2)", paste(rep("a long title", 30), collapse = " "))))
err <- captured$value
said <- captured$said
expect_true(grepl("^2 lookups of remote resources failed \\(listed above\\)", err), info = err)
expect_true(any(grepl("codecheck.yml of 2020-020 (osf::7TWR2)", said, fixed = TRUE)))
expect_true(any(grepl("a long title a long", said, fixed = TRUE)) && all(nchar(said) < 200),
            info = "a long entry is shortened")
expect_true(nchar(err) < 1000)
# a test that renders with live services and is not about this can carry on
options(codecheck.fail_on_outages = FALSE)
expect_warning(capture_messages(codecheck:::stop_on_lookup_failures("x - HTTP 503")), "1 lookup of remote")
options(codecheck.fail_on_outages = NULL)

# A paper without a DOI is searched by title and first author. OpenAlex dropped
# the authorships.author.display_name filter and answers 400 for it, which made
# every such search a failed lookup in every render; a search that answers no
# match is an absence, not a failure
asked <- character(0)
no_match <- function(url, ...) {
  asked <<- c(asked, url)
  if (grepl("filter=title.search", url, fixed = TRUE)) {
    return(mock_json_response(url, list(meta = list(count = 0), results = list())))
  }
  mock_response(url, 404L)
}
with_mocked_codecheck(list(codecheck_GET_openalex = no_match), {
  result <- codecheck:::get_openalex_id_result("https://cmmid.github.io/report.pdf",
                                               paper_title = "Model of isolation, contact tracing",
                                               first_author_name = "Adam Kucharski")
})
expect_equal(result$status, "absent")
search <- asked[grepl("title.search", asked)]
expect_true(grepl(",raw_author_name.search:Adam%20Kucharski", search, fixed = TRUE), info = search)
expect_false(grepl("display_name", search, fixed = TRUE))

# A download that fails keeps a good cert.pdf and leaves no part of a file
certs <- tempfile("certs")
dir.create(file.path(certs, "2020-001"), recursive = TRUE)
writeLines("a good certificate", file.path(certs, "2020-001", "cert.pdf"))
CONFIG$CERTS_DIR[["cert"]] <- certs
with_mocked_codecheck(list(get_cert_link = function(report, cert_id) "https://zenodo.org/f/cert.pdf",
                           codecheck_GET_retry = function(url, ...) mock_response(url, 503L)), {
  expect_warning(status <- codecheck:::download_cert_pdf("https://doi.org/10.5281/zenodo.1", "2020-001"),
                 "Unsuccessful")
})
expect_equal(status, 0)
expect_equal(readLines(file.path(certs, "2020-001", "cert.pdf")), "a good certificate")
expect_equal(list.files(file.path(certs, "2020-001")), "cert.pdf")

tinytest::using(ttdo)

source(system.file("extdata", "config.R", package = "codecheck"))

# Unit tests: normalize_codechecker_list() ----

expect_equal(nrow(codecheck:::normalize_codechecker_list(NULL)), 0)
expect_equal(names(codecheck:::normalize_codechecker_list(NULL)), codecheck:::CODECHECKER_LIST_COLUMNS)

# The volunteer list has every column
volunteer_shaped <- data.frame(
  name = "A Person", handle = "@aperson", ORCID = "0000-0000-0000-0001",
  contact = "see ORCID page", fields = "geo", languages = "R",
  stringsAsFactors = FALSE
)
expect_equal(names(codecheck:::normalize_codechecker_list(volunteer_shaped)),
             codecheck:::CODECHECKER_LIST_COLUMNS)

# The institutional list has none of contact/fields/languages, and an
# institution column that is dropped rather than carried along
institutional_shaped <- data.frame(
  name = "B Person", handle = "@bperson", ORCID = "0000-0000-0000-0002",
  institution = "TU Delft", stringsAsFactors = FALSE
)
normalized <- codecheck:::normalize_codechecker_list(institutional_shaped)
expect_equal(names(normalized), codecheck:::CODECHECKER_LIST_COLUMNS)
expect_true(is.na(normalized$fields))
expect_false("institution" %in% names(normalized))

# A list read before it carried an ORCID column degrades to "no ORCID known"
# rather than failing the render
no_orcid_column <- data.frame(handle = "@cperson", institution = "TU Delft",
                              stringsAsFactors = FALSE)
expect_true(is.na(codecheck:::normalize_codechecker_list(no_orcid_column)$ORCID))

# Unit tests: codechecker_record_to_profile() ----

record <- function(...) {
  values <- list(...)
  defaults <- list(name = NA_character_, handle = NA_character_, ORCID = NA_character_,
                   contact = NA_character_, fields = NA_character_,
                   languages = NA_character_, source = "volunteer")
  defaults[names(values)] <- values
  do.call(data.frame, c(defaults, list(stringsAsFactors = FALSE)))
}

profile <- codecheck:::codechecker_record_to_profile(
  record(name = "A Person", handle = "@aperson", ORCID = "0000-0000-0000-0001")
)
expect_equal(profile$name, "A Person")
# The @ prefix of the list is not part of the handle used in URLs
expect_equal(profile$github_handle, "aperson")
expect_equal(profile$orcid, "0000-0000-0000-0001")
expect_equal(profile$source, "volunteer")

# NA/empty handle or ORCID become NULL, not the string "NA": the metadata
# template keys its GitHub/ORCID rows off their absence
no_handle <- codecheck:::codechecker_record_to_profile(
  record(name = "C Person", handle = NA_character_, ORCID = "0000-0000-0000-0003",
         source = "agile")
)
expect_null(no_handle$github_handle)
expect_equal(no_handle$orcid, "0000-0000-0000-0003")
expect_equal(no_handle$source, "agile")

no_orcid <- codecheck:::codechecker_record_to_profile(
  record(name = "D Person", handle = "@dperson", ORCID = "", source = "institutional")
)
expect_null(no_orcid$orcid)
expect_equal(no_orcid$github_handle, "dperson")

# Integration tests: the three live lists ----
# Network-dependent, like the live codecheckers.csv test in
# test_codechecker_metadata.R - a failed fetch degrades to an empty list.

records <- codecheck:::all_codechecker_records()
expect_equal(names(records), c(codecheck:::CODECHECKER_LIST_COLUMNS, "source"))
expect_true(all(records$source %in% names(codecheck:::CODECHECKER_LIST_URLS)))
# Volunteers come first, so that their richer record wins for anyone who is
# also in one of the other two lists
if (any(records$source != "volunteer")) {
  expect_equal(records$source[1], "volunteer")
  expect_true(max(which(records$source == "volunteer")) <
                min(which(records$source != "volunteer")))
}

# A codechecker known only through the institutional list resolves to a
# profile with a GitHub handle, which before the fallback they could not
institutional <- codecheck:::get_institutional_codecheckers_data()
if (nrow(institutional) > 0 && any(!is.na(institutional$ORCID))) {
  known <- institutional[!is.na(institutional$ORCID) & !is.na(institutional$handle), ][1, ]
  found <- codecheck:::get_codechecker_profile(known$ORCID)
  expect_false(is.null(found))
  expect_equal(found$github_handle, gsub("^@", "", known$handle))
  expect_true(found$source %in% c("volunteer", "institutional"))

  # ...and the same person is found by their handle
  by_handle <- codecheck:::get_codechecker_profile_by_handle(known$handle)
  expect_false(is.null(by_handle))
  expect_equal(by_handle$orcid, known$ORCID)

  # Handles are matched case-insensitively, as GitHub itself treats them
  expect_equal(
    codecheck:::get_codechecker_profile_by_handle(toupper(known$handle))$orcid,
    known$ORCID
  )
  # ...and so is the "X" checksum digit an ORCID may end in
  expect_equal(
    codecheck:::get_codechecker_profile(tolower(known$ORCID))$orcid,
    known$ORCID
  )
}

agile <- codecheck:::get_agile_codecheckers_data()
if (nrow(agile) > 0 && any(!is.na(agile$handle))) {
  known <- agile[!is.na(agile$handle) & !is.na(agile$ORCID), ][1, ]
  expect_equal(codecheck:::get_github_handle_by_name(known$name),
               gsub("^@", "", known$handle))
}

# Unknown identifiers stay unknown in all three lookups
expect_null(codecheck:::get_codechecker_profile("0000-0000-0000-0000"))
expect_null(codecheck:::get_codechecker_profile("9999-9999-9999-9999"))
expect_null(codecheck:::get_codechecker_profile_by_handle("no-such-handle-anywhere"))
expect_null(codecheck:::get_github_handle_by_name("No Such Person At All"))
expect_null(codecheck:::get_codechecker_profile(NA))
expect_null(codecheck:::get_codechecker_profile_by_handle(""))

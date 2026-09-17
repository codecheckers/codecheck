tinytest::using(ttdo)

source("mocks.R")
source(system.file("extdata", "config.R", package = "codecheck"))

# Unit tests: fediverse_handle() / fediverse_profile_url() ----

expect_equal(codecheck:::fediverse_handle("@codecheck@fediscience.org"), "@codecheck@fediscience.org")
expect_equal(codecheck:::fediverse_handle(" codecheck@FediScience.org "), "@codecheck@fediscience.org")
# Not guessed at: a URL, a handle with no instance, nothing
expect_null(codecheck:::fediverse_handle("https://fediscience.org/@codecheck"))
expect_null(codecheck:::fediverse_handle("@codecheck"))
expect_null(codecheck:::fediverse_handle(""))
expect_null(codecheck:::fediverse_handle(NA_character_))
expect_null(codecheck:::fediverse_handle(NULL))

expect_equal(codecheck:::fediverse_profile_url("@codecheck@fediscience.org"),
             "https://fediscience.org/@codecheck")
expect_null(codecheck:::fediverse_profile_url("not an account"))
# pandoc reads @word as a citation, so the link text carries entities
expect_equal(codecheck:::fediverse_link_text("@codecheck@fediscience.org"), "&#64;codecheck&#64;fediscience.org")

# Unit tests: split_venue_hashtags() ----

expect_equal(codecheck:::split_venue_hashtags("AGILEGIS; #GIScience;;"), c("AGILEGIS", "GIScience"))
expect_equal(codecheck:::split_venue_hashtags(NA_character_), character(0))
expect_equal(codecheck:::split_venue_hashtags(""), character(0))

# The codechecker lists carry the column ----

expect_true("fediverse" %in% codecheck:::CODECHECKER_LIST_COLUMNS)
# A list read before the column landed has no account, not an error
old_list <- data.frame(name = "A Person", handle = "@aperson", ORCID = "0000-0000-0000-0001",
                       stringsAsFactors = FALSE)
expect_true(is.na(codecheck:::normalize_codechecker_list(old_list)$fediverse))

profile <- codecheck:::codechecker_record_to_profile(data.frame(
  name = "A Person", handle = "@aperson", ORCID = "0000-0000-0000-0001",
  contact = NA_character_, fields = NA_character_, languages = NA_character_,
  fediverse = "aperson@example.social", source = "volunteer", stringsAsFactors = FALSE
))
expect_equal(profile$fediverse, "@aperson@example.social")

# persons.csv wins over the codechecker lists ----

persons <- tempfile(fileext = ".csv")
writeLines(c("orcid,wikidata,fediverse",
             "0000-0000-0000-0001,Q1,@registered@fediscience.org",
             "0000-0000-0000-0002,,not-an-account",
             "0000-0000-0000-000X,,@x@example.social"), persons)
codecheck:::load_person_fediverse(persons)
expect_equal(codecheck:::person_fediverse("0000-0000-0000-0001", profile), "@registered@fediscience.org")
# A malformed entry is no account, and the list's account is used instead
expect_equal(codecheck:::person_fediverse("0000-0000-0000-0002", profile), "@aperson@example.social")
expect_equal(codecheck:::person_fediverse("0000-0000-0000-000x"), "@x@example.social")
expect_null(codecheck:::person_fediverse("0000-0000-0000-0003"))

# A column with no account in it is an empty lookup, as in the register today
empty_column <- tempfile(fileext = ".csv")
writeLines(c("orcid,wikidata,fediverse", "0000-0000-0000-0001,Q1,", "0000-0000-0000-0002,,"), empty_column)
expect_silent(codecheck:::load_person_fediverse(empty_column))
expect_null(codecheck:::person_fediverse("0000-0000-0000-0001"))

# A file without the column is an empty lookup
no_column <- tempfile(fileext = ".csv")
writeLines(c("orcid,wikidata", "0000-0000-0000-0001,Q1"), no_column)
codecheck:::load_person_fediverse(no_column)
expect_null(codecheck:::person_fediverse("0000-0000-0000-0001"))
codecheck:::load_person_fediverse(NULL)

# The person page and its metadata ----

with_mocked_codecheck(list(resolve_codechecker_profile = function(identifier) profile), {
  codecheck:::load_person_fediverse(persons)
  html <- codecheck:::generate_codechecker_metadata_html("0000-0000-0000-0001")
  expect_true(grepl('href="https://fediscience.org/@registered"', html, fixed = TRUE))
  expect_true(grepl('rel="me noopener"', html, fixed = TRUE))

  jsonld <- jsonlite::fromJSON(codecheck:::generate_person_schema_org(
    "0000-0000-0000-0001", "A Person", "aperson",
    data.frame(Certificate = character(0), Repository = character(0),
               `Check date` = character(0), Role = character(0), check.names = FALSE)))
  person <- jsonld$`@graph`
  same_as <- unlist(if (is.data.frame(person)) person$sameAs[1] else person[[1]]$sameAs)
  expect_true("https://fediscience.org/@registered" %in% same_as)
  expect_true("https://github.com/aperson" %in% same_as)

  stats <- codecheck:::build_person_stats_field("0000-0000-0000-0001",
    data.frame(`Certificate ID` = character(0), Venue = character(0), Type = character(0),
               Role = character(0), check.names = FALSE))
  expect_equal(stats$fediverse, "@registered@fediscience.org")
})
codecheck:::load_person_fediverse(NULL)

# sync_persons_file() keeps what it does not write ----

synced <- tempfile(fileext = ".csv")
writeLines(c("orcid,wikidata,fediverse",
             "0000-0000-0000-0002,,@kept@example.social",
             "0000-0000-0000-0003,Q3,"), synced)
codecheck:::sync_persons_file(synced, c(`0000-0000-0000-0001` = "Q1"))
expect_equal(readLines(synced),
             c("orcid,wikidata,fediverse",
               "0000-0000-0000-0001,Q1,",
               "0000-0000-0000-0002,,@kept@example.social",
               "0000-0000-0000-0003,Q3,"))

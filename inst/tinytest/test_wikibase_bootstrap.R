tinytest::using(ttdo)

source("mocks.R")

# plan_wikibase_entities() is the half of the bootstrap that decides what to
# create, kept free of network access so the decision can be tested directly.
# The instance itself is disposable, so being able to rebuild it from empty -
# and to repeat a partially failed run - is the property that matters most.

empty <- data.frame(local_id = character(0), wikidata_id = character(0),
                    label = character(0), stringsAsFactors = FALSE)

# An empty instance: everything is created ----

plan <- codecheck:::plan_wikibase_entities(empty)
expect_true(all(plan$action == "create"))
expect_true(all(plan$kind %in% c("property", "item")))

# One property per distinct Wikidata property, plus the mapping property.
properties <- codecheck::wikidata_properties()
expect_equal(
  sum(plan$kind == "property"),
  length(unique(properties$property)) + 1L
)
expect_equal(sum(plan$kind == "item"), length(codecheck:::WIKIDATA_ITEMS))

# The mapping property is the one entity without a Wikidata counterpart, and it
# has to be created before anything that refers to it.
mapping <- plan[is.na(plan$wikidata_id), ]
expect_equal(nrow(mapping), 1)
expect_equal(mapping$label, "Wikidata entity")
expect_equal(mapping$datatype, "external-id")

# Every property carries the datatype from the model; a Wikibase property
# created with the wrong one cannot be corrected afterwards.
expect_true(all(plan$datatype[plan$kind == "property"] %in% codecheck:::WIKIBASE_DATATYPES))
doi <- plan[!is.na(plan$wikidata_id) & plan$wikidata_id == "P356", ]
expect_equal(doi$datatype, "external-id")
expect_equal(plan$datatype[!is.na(plan$wikidata_id) & plan$wikidata_id == "P577"], "time")
expect_equal(plan$datatype[!is.na(plan$wikidata_id) & plan$wikidata_id == "P1476"], "monolingualtext")
expect_equal(plan$datatype[!is.na(plan$wikidata_id) & plan$wikidata_id == "P31"], "wikibase-item")

# Items carry no datatype.
expect_true(all(is.na(plan$datatype[plan$kind == "item"])))

# A qualifier and a reference need a property on the instance as much as a
# statement does: without P972 no catalog code can be written, and without P854
# and P813 no statement can carry the reference that marks it as ours. They have
# to exist from the first run, not be discovered when the first certificate is
# loaded.
expect_true(all(c("P972", "P854", "P813") %in% plan$wikidata_id))
expect_equal(plan$datatype[!is.na(plan$wikidata_id) & plan$wikidata_id == "P854"], "url")
expect_equal(plan$datatype[!is.na(plan$wikidata_id) & plan$wikidata_id == "P813"], "time")
expect_equal(plan$label[!is.na(plan$wikidata_id) & plan$wikidata_id == "P972"], "catalog")

# Why each property exists, carried through to the listing page.
expect_true(all(plan$role %in% c("mapping", "statement", "qualifier", "reference", "class item")))
expect_equal(plan$role[is.na(plan$wikidata_id)], "mapping")
expect_true(all(plan$role[plan$kind == "item"] == "class item"))
expect_equal(plan$role[!is.na(plan$wikidata_id) & plan$wikidata_id == "P813"], "reference")

# A property the model uses in two positions is still one property: P31 is a
# statement on three entity kinds and appears once.
expect_equal(sum(plan$wikidata_id == "P31", na.rm = TRUE), 1L)

# A populated instance: nothing is created twice ----

populated <- data.frame(
  local_id = c("P1", paste0("P", seq_len(nrow(plan[plan$kind == "property", ]) - 1) + 1),
               paste0("Q", seq_len(sum(plan$kind == "item")))),
  wikidata_id = c(NA_character_,
                  plan$wikidata_id[plan$kind == "property" & !is.na(plan$wikidata_id)],
                  plan$wikidata_id[plan$kind == "item"]),
  label = c("Wikidata entity",
            plan$label[plan$kind == "property" & !is.na(plan$wikidata_id)],
            plan$label[plan$kind == "item"]),
  stringsAsFactors = FALSE
)
replanned <- codecheck:::plan_wikibase_entities(populated)
expect_true(all(replanned$action == "present"))

# Identity is the Wikidata id, not the label: a property renamed on the instance
# is still recognised, which is what keeps a rerun from duplicating it.
renamed <- populated
renamed$label[renamed$wikidata_id == "P356" & !is.na(renamed$wikidata_id)] <- "digital object identifier"
expect_true(all(codecheck:::plan_wikibase_entities(renamed)$action == "present"))

# A partial instance: only the gaps are created ----

partial <- populated[populated$wikidata_id %in% c("P31", "P356") | is.na(populated$wikidata_id), ]
partial_plan <- codecheck:::plan_wikibase_entities(partial)
expect_equal(sum(partial_plan$action == "present"), 3L)  # mapping property, P31, P356
expect_true(sum(partial_plan$action == "create") > 0)
# The mapping property is present, so it is not created a second time.
expect_equal(partial_plan$action[is.na(partial_plan$wikidata_id)], "present")

# The stock seed entities do not count as ours: wikibase.cloud ships Q1-Q6 and
# P1-P6 with labels like "instance of", which must not be mistaken for the
# model's properties, since they carry no Wikidata mapping.
seeded <- data.frame(
  local_id = c("P5", "P6", "Q3"),
  wikidata_id = c(NA_character_, NA_character_, NA_character_),
  label = c("instance of", "subclass of", "human"),
  stringsAsFactors = FALSE
)
seeded_plan <- codecheck:::plan_wikibase_entities(seeded)
expect_true(any(seeded_plan$wikidata_id[seeded_plan$action == "create"] == "P31", na.rm = TRUE))

# Property labels must be unique in a Wikibase, and the seed data occupies
# "instance of" and "subclass of". A colliding property is disambiguated by its
# Wikidata id rather than by deleting somebody else's entity.
seeded_p31 <- seeded_plan[!is.na(seeded_plan$wikidata_id) & seeded_plan$wikidata_id == "P31", ]
expect_equal(seeded_p31$label, "instance of (P31)")
# Items are not affected: Wikibase allows duplicate item labels.
expect_true(all(seeded_plan$label[seeded_plan$kind == "item"] ==
                  plan$label[plan$kind == "item"]))
# Without a collision the plain label is kept.
expect_equal(plan$label[!is.na(plan$wikidata_id) & plan$wikidata_id == "P31"], "instance of")

# Credentials are required for a real run ----

user <- Sys.getenv("WIKIBASE_USER")
token <- Sys.getenv("WIKIBASE_TOKEN")
Sys.setenv(WIKIBASE_USER = "", WIKIBASE_TOKEN = "")
expect_error(codecheck:::wikibase_session(), pattern = "Special:BotPasswords")
Sys.setenv(WIKIBASE_USER = user, WIKIBASE_TOKEN = token)

# The payload a created entity carries ----

# wbeditentity has to be right the first time: a property's datatype cannot be
# changed after creation, only deleted and recreated.
sent <- NULL
session <- list(handle = NULL, csrf = "token")
with_mocked_codecheck(
  list(wikibase_post = function(session, params, what) {
    sent <<- params
    list(entity = list(id = "P42"))
  }),
  {
    row <- plan[!is.na(plan$wikidata_id) & plan$wikidata_id == "P356", ]
    expect_equal(codecheck:::create_wikibase_entity(session, row, "P1"), "P42")
  }
)
expect_equal(sent$action, "wbeditentity")
expect_equal(sent$new, "property")
payload <- jsonlite::fromJSON(sent$data, simplifyVector = FALSE)
expect_equal(payload$datatype, "external-id")
expect_equal(payload$labels$en$value, "DOI")
# The Wikidata counterpart is stated through the mapping property, whose local
# id is not P356 - that is the whole point of the mapping.
expect_equal(payload$claims[[1]]$mainsnak$property, "P1")
expect_equal(payload$claims[[1]]$mainsnak$datavalue$value, "P356")

# The mapping property itself has no counterpart to state.
sent <- NULL
with_mocked_codecheck(
  list(wikibase_post = function(session, params, what) {
    sent <<- params
    list(entity = list(id = "P1"))
  }),
  codecheck:::create_wikibase_entity(session, plan[is.na(plan$wikidata_id), ], NA_character_)
)
mapping_payload <- jsonlite::fromJSON(sent$data, simplifyVector = FALSE)
expect_null(mapping_payload$claims)
expect_equal(mapping_payload$datatype, "external-id")

# An item is created without a datatype, which wbeditentity rejects on items.
sent <- NULL
with_mocked_codecheck(
  list(wikibase_post = function(session, params, what) {
    sent <<- params
    list(entity = list(id = "Q7"))
  }),
  codecheck:::create_wikibase_entity(session, plan[plan$kind == "item", ][1, ], "P1")
)
expect_equal(sent$new, "item")
expect_null(jsonlite::fromJSON(sent$data, simplifyVector = FALSE)$datatype)

# Reading the instance back ----

# The mapping is read off the instance rather than kept in a file, so what
# wikibase_mapping() makes of the API's answer is what keeps a rerun from
# duplicating entities.
entities <- list(
  P1 = list(labels = list(en = list(value = "Wikidata entity")), claims = list()),
  P2 = list(labels = list(en = list(value = "DOI")),
            claims = list(P1 = list(list(mainsnak = list(datavalue = list(value = "P356")))))),
  Q1 = list(labels = list(en = list(value = "human")),
            claims = list(P1 = list(list(mainsnak = list(datavalue = list(value = "Q5"))))))
)
fake_get <- function(handle, params) {
  if (identical(params$list, "allpages")) {
    prefix <- if (identical(params$apnamespace, 120)) "Item:" else "Property:"
    ids <- names(entities)[startsWith(names(entities), if (prefix == "Item:") "Q" else "P")]
    return(list(query = list(allpages = lapply(ids, function(id) list(title = paste0(prefix, id))))))
  }
  ids <- strsplit(params$ids, "|", fixed = TRUE)[[1]]
  list(entities = entities[ids])
}

mapping <- with_mocked_codecheck(list(wikibase_get = fake_get),
                                 codecheck:::wikibase_mapping())
expect_equal(sort(mapping$local_id), c("P1", "P2", "Q1"))
expect_true(is.na(mapping$wikidata_id[mapping$local_id == "P1"]))
expect_equal(mapping$wikidata_id[mapping$local_id == "P2"], "P356")
expect_equal(mapping$wikidata_id[mapping$local_id == "Q1"], "Q5")

# An empty instance reads back as an empty mapping, which is what makes the
# first run plan everything.
empty_mapping <- with_mocked_codecheck(
  list(wikibase_get = function(handle, params) list(query = list(allpages = list()))),
  codecheck:::wikibase_mapping()
)
expect_equal(nrow(empty_mapping), 0L)
expect_true(all(codecheck:::plan_wikibase_entities(empty_mapping)$action == "create"))

# The listing page ----

# The instance mints its own P- and Q-numbers, so the only readable index of
# what it holds is the one the bootstrap writes.
listed <- plan
listed$local_id <- paste0(ifelse(listed$kind == "property", "P", "Q"), seq_len(nrow(listed)))
page <- codecheck:::wikibase_report_wikitext(listed,
                                             generated_at = as.POSIXct("2026-09-02 12:00:00", tz = "UTC"))
page <- paste(page, collapse = "\n")
expect_true(grepl("bootstrap_wikibase()", page, fixed = TRUE))
expect_true(grepl("register/issues/50", page, fixed = TRUE))
expect_true(grepl("== Properties ==", page, fixed = TRUE))
expect_true(grepl("== Class items ==", page, fixed = TRUE))
expect_true(grepl("2026-09-02 12:00:00", page, fixed = TRUE))

# Every entity is listed, linked by its local id, next to its Wikidata
# counterpart - the mapping is the reason the page exists.
expect_true(all(vapply(listed$local_id, function(id) {
  grepl(paste0("|", id, "]]"), page, fixed = TRUE)
}, logical(1))))
expect_true(grepl("[[Property:P1|P1]]", page, fixed = TRUE))
expect_true(grepl("https://www.wikidata.org/wiki/Property:P356 P356]", page, fixed = TRUE))
expect_true(grepl("https://www.wikidata.org/wiki/Q5 Q5]", page, fixed = TRUE))
# The mapping property has no counterpart, and says so rather than showing NA.
expect_false(grepl("NA", page, fixed = TRUE))

# An entity that was planned but not created (a failed run, resumed later)
# shows as missing rather than silently vanishing from the index.
partial_listing <- listed
partial_listing$local_id[2] <- NA_character_
expect_true(grepl("''missing''",
                  paste(codecheck:::wikibase_report_wikitext(partial_listing), collapse = "\n"),
                  fixed = TRUE))

# Coming back when the server asks us to ----

# A MediaWiki under load does not refuse a write, it asks for it again later.
# All of these used to end a bootstrap halfway through.
expect_equal(codecheck:::wikibase_retry_after(list(error = list(code = "maxlag", lag = 8))), 8)
expect_equal(codecheck:::wikibase_retry_after(list(error = list(code = "ratelimited"))), 5)
expect_equal(codecheck:::wikibase_retry_after(list(error = list(code = "readonly"))), 5)
# The wait doubles per attempt, and is capped so a run cannot stall unnoticed.
expect_equal(codecheck:::wikibase_retry_after(list(error = list(code = "maxlag", lag = 5)), attempt = 3), 20)
expect_equal(codecheck:::wikibase_retry_after(list(error = list(code = "maxlag", lag = 30)), attempt = 5), 60)

# Everything else is a real error: a bad token or a duplicate label does not
# get better by being sent again.
expect_true(is.na(codecheck:::wikibase_retry_after(list(error = list(code = "badtoken")))))
expect_true(is.na(codecheck:::wikibase_retry_after(list(entity = list(id = "P1")))))

# A 503 or a 429 carries the wait in the response rather than in the body.
throttled <- structure(list(status_code = 503L,
                            headers = structure(list(`retry-after` = "12"), class = "insensitive")),
                       class = "response")
expect_equal(codecheck:::wikibase_retry_after(list(), throttled), 12)
expect_true(is.na(codecheck:::wikibase_retry_after(list(), structure(list(status_code = 200L),
                                                                     class = "response"))))

# Saying who we are ----

# Wikimedia's policy asks for a descriptive agent with a way to reach us, and
# the busier endpoints answer an anonymous client with 403.
agent <- codecheck:::wikibase_user_agent()
expect_true(grepl("^codecheck-R/", agent))
expect_true(grepl("codecheckers/codecheck", agent, fixed = TRUE))
withr_option <- getOption("codecheck.contact")
options(codecheck.contact = "codecheck@example.org")
expect_true(grepl("codecheck@example.org", codecheck:::wikibase_user_agent(), fixed = TRUE))
options(codecheck.contact = withr_option)

# Asking about many identifiers in one query ----

# Resolution asks "which of these DOIs already has an item". One query per DOI
# is 132 round trips against a service that rate limits.
chunks <- codecheck:::wikibase_values_chunks(c("10.1/a", "10.1/b", "10.1/a"), size = 2)
expect_equal(length(chunks), 1L)          # the duplicate is dropped
expect_equal(unname(chunks), "\"10.1/a\" \"10.1/b\"")
expect_equal(length(codecheck:::wikibase_values_chunks(paste0("10.1/", 1:130), size = 50)), 3L)
expect_equal(length(codecheck:::wikibase_values_chunks(c(NA, ""))), 0L)
# Item ids are not string literals, so they can be emitted unquoted.
expect_equal(unname(codecheck:::wikibase_values_chunks(c("wd:Q1", "wd:Q2"), quote = FALSE)),
             "wd:Q1 wd:Q2")

# Creating versus updating ----

# The same call, and the difference between a rerun that converges and one that
# duplicates.
sent <- NULL
capture <- function(session, params, what) {
  sent <<- params
  list(entity = list(id = "P9"))
}
with_mocked_codecheck(list(wikibase_post = capture), {
  codecheck:::wikibase_edit_entity(session, list(labels = list()), kind = "property",
                                   summary = "create it")
})
expect_equal(sent$new, "property")
expect_null(sent$id)
expect_equal(sent$summary, "create it")
expect_equal(sent$bot, 1)

with_mocked_codecheck(list(wikibase_post = capture), {
  codecheck:::wikibase_edit_entity(session, list(labels = list()), id = "P9",
                                   summary = "fix it")
})
expect_equal(sent$id, "P9")
expect_null(sent$new)

expect_error(codecheck:::wikibase_edit_entity(session, list(), kind = "item", id = "Q1"),
             pattern = "not both")
expect_error(codecheck:::wikibase_edit_entity(session, list()), pattern = "not both")

# Drift is repaired, agreement costs no edit ----

# The instance is generated, so a label the model no longer produces is drift
# rather than somebody's edit to keep.
mapping_now <- data.frame(local_id = c("P9", "P11"),
                          wikidata_id = c("P31", "P1476"),
                          label = c("instance of", "title (P1476)"),
                          stringsAsFactors = FALSE)
row_ok <- data.frame(kind = "property", local_id = "P9", label = "instance of",
                     stringsAsFactors = FALSE)
row_drifted <- data.frame(kind = "property", local_id = "P11", label = "title",
                          stringsAsFactors = FALSE)

edits <- 0
with_mocked_codecheck(list(wikibase_post = function(session, params, what) {
  edits <<- edits + 1
  sent <<- params
  list(entity = list(id = "P11"))
}), {
  expect_false(codecheck:::reconcile_wikibase_entity(session, row_ok, mapping_now))
  expect_true(codecheck:::reconcile_wikibase_entity(session, row_drifted, mapping_now))
})
expect_equal(edits, 1)
expect_equal(sent$id, "P11")
expect_true(grepl("title", sent$data, fixed = TRUE))

# A rerun does not rename what it created ----

# On every run after the first, the instance holds our own properties under the
# labels we gave them. Counting that as a label collision renamed "title" to
# "title (P1476)" on the second run, and would have renamed it again on the
# third - and the reconciliation step would have written each of those.
first <- codecheck:::plan_wikibase_entities(empty)
after_first <- data.frame(
  local_id = paste0("X", seq_len(nrow(first))),
  wikidata_id = first$wikidata_id,
  label = first$label,
  stringsAsFactors = FALSE
)
second <- codecheck:::plan_wikibase_entities(after_first)
expect_equal(second$label, first$label)
expect_true(all(second$action == "present"))
# And a third run is identical again, which is what makes the run idempotent
# rather than merely convergent.
after_second <- after_first
after_second$label <- second$label
expect_equal(codecheck:::plan_wikibase_entities(after_second)$label, first$label)

# The seed data still occupies "instance of", so that one property stays
# disambiguated on every run - including when our own copy is already there.
seeded_and_ours <- rbind(
  seeded,
  data.frame(local_id = "P9", wikidata_id = "P31", label = "instance of (P31)",
             stringsAsFactors = FALSE)
)
rerun <- codecheck:::plan_wikibase_entities(seeded_and_ours)
expect_equal(rerun$label[!is.na(rerun$wikidata_id) & rerun$wikidata_id == "P31"],
             "instance of (P31)")
expect_equal(rerun$action[!is.na(rerun$wikidata_id) & rerun$wikidata_id == "P31"], "present")

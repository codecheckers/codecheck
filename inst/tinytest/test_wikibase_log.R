tinytest::using(ttdo)

# The export has two routes and one log: our own Wikibase is written through
# the API, Wikidata by a person pasting QuickStatements under their own account.
# The manual route is the one that needs the record, since a batch somebody
# pasted cannot be reconstructed afterwards.

log_file <- tempfile(fileext = ".csv")

codecheck:::wikibase_log(target = "wikibase", action = "create", kind = "property",
                         id = "P26", label = "catalog", status = "done",
                         file = log_file)
codecheck:::wikibase_log(target = "wikibase", action = "relabel", kind = "property",
                         id = "P11", label = "title", status = "done",
                         file = log_file)

entries <- codecheck:::wikibase_log_read(log_file)
expect_equal(nrow(entries), 2)
expect_equal(colnames(entries), codecheck:::WIKIBASE_LOG_COLUMNS)
expect_equal(entries$id, c("P26", "P11"))
expect_equal(entries$action, c("create", "relabel"))
# Columns not given are recorded as missing rather than dropping the row's shape.
expect_true(all(is.na(entries$batch)))
# The time is stamped by the log, not by the caller.
expect_true(all(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T", entries$time)))

# No log file, no log: an exploratory dry run should not litter the working
# directory, and the entry is still returned for the caller to use.
quiet <- codecheck:::wikibase_log(target = "wikibase", action = "create",
                                  id = "P1", file = NULL)
expect_equal(nrow(quiet), 1)
expect_equal(nrow(codecheck:::wikibase_log_read(NULL)), 0L)
expect_equal(colnames(codecheck:::wikibase_log_read(NULL)), codecheck:::WIKIBASE_LOG_COLUMNS)

# The option is the fallback when no path is passed.
old_option <- getOption("codecheck.wikibase_log")
options(codecheck.wikibase_log = log_file)
expect_equal(codecheck:::wikibase_log_file(), log_file)
expect_equal(codecheck:::wikibase_log_file("elsewhere.csv"), "elsewhere.csv")
options(codecheck.wikibase_log = old_option)

# QuickStatements: what a person pastes, kept ----

batch_dir <- tempfile()
dir.create(batch_dir)
commands <- c("CREATE", "LAST\tLen\t\"CODECHECK Certificate 2020-001\"",
              "LAST\tP31\tQ116740091")
path <- codecheck::quickstatements_write(commands, "certificates-test",
                                         dir = batch_dir, file = log_file)

expect_true(file.exists(path))
expect_equal(basename(path), "certificates-test.qs")
# The file is what was pasted, so it has to be exactly the commands - no
# header, no commentary.
expect_equal(readLines(path), commands)

prepared <- codecheck:::wikibase_log_read(log_file)
# which(): rows logged without a batch have NA there, and a plain
# comparison would carry NA rows into the result.
prepared <- prepared[which(prepared$batch == "certificates-test"), ]
expect_equal(nrow(prepared), 1)
expect_equal(prepared$status, "prepared")
expect_equal(prepared$target, "wikidata")
expect_equal(prepared$detail, "3 commands")

# Submitting is the step the code cannot observe, so it is recorded by hand,
# with the batch URL QuickStatements gives out.
codecheck::quickstatements_submitted("certificates-test",
                                     url = "https://quickstatements.toolforge.org/#/batch/1234",
                                     note = "2 of 3 commands applied",
                                     file = log_file)
both <- codecheck:::wikibase_log_read(log_file)
both <- both[which(both$batch == "certificates-test"), ]
expect_equal(both$status, c("prepared", "submitted"))
expect_equal(both$id[2], "https://quickstatements.toolforge.org/#/batch/1234")
expect_equal(both$detail[2], "2 of 3 commands applied")

# Recording a batch nobody prepared is suspicious enough to warn about, but not
# to refuse: the log exists to record what happened, including the unplanned.
expect_warning(
  codecheck::quickstatements_submitted("never-prepared", file = log_file),
  pattern = "No prepared batch"
)

# Recording a batch retires the file it was pasted from ----

# A .qs file whose commands have been run is the duplicate-paste hazard itself,
# so recording the run has to take the file out of the way.
dir <- tempfile(); dir.create(dir)
log_file <- tempfile(fileext = ".csv")
path <- quickstatements_write(c("CREATE", "LAST\tLen\t\"a\""), "wikidata-works",
                              dir = dir, target = "wikidata", file = log_file)
expect_true(file.exists(path))

quickstatements_submitted("wikidata-works", url = "https://editgroups.toolforge.org/b/QSv2T/1",
                          file = log_file)
expect_false(file.exists(path))
expect_true(file.exists(paste0(path, ".submitted")))
# The commands survive the rename: which of them failed is a real question.
expect_equal(readLines(paste0(path, ".submitted"))[1], "CREATE")

# Recording it twice is not an error, and does not lose the retired file.
expect_silent(quickstatements_submitted("wikidata-works", file = log_file))
expect_true(file.exists(paste0(path, ".submitted")))

# Nothing to retire is not a failure: a batch may be recorded from elsewhere.
expect_true(is.na(codecheck:::quickstatements_retire(NA_character_)))
expect_true(is.na(codecheck:::quickstatements_retire(file.path(dir, "gone.qs"))))
expect_true(is.na(codecheck:::quickstatements_retire("https://example.org/batch/1")))

# Splitting a batch at Wikidata's edit rate limit ----

item <- function(n) c("CREATE", paste0("LAST\tLen\t\"", n, "\""),
                      paste0("LAST\tP31\tQ", n))
many <- unlist(lapply(1:10, item))

# Under the limit there is one batch and no renaming.
expect_equal(length(codecheck:::quickstatements_chunks(many, 10)), 1L)
expect_equal(codecheck:::quickstatements_chunks(many, 10)[[1]], many)

chunks <- codecheck:::quickstatements_chunks(many, 4)
expect_equal(length(chunks), 3L)
expect_equal(sum(vapply(chunks, length, 1L)), length(many))
# Whole items only: a chunk boundary inside an item would leave its LAST lines
# attached to whatever the previous chunk created last.
expect_true(all(vapply(chunks, function(x) x[1] == "CREATE", logical(1))))
expect_equal(vapply(chunks, function(x) sum(x == "CREATE"), 1L), c(4L, 4L, 2L))

# Commands that are not creates have no LAST to keep together.
updates <- paste0("Q", 1:10, "\tP31\tQ5")
expect_equal(length(codecheck:::quickstatements_chunks(updates, 4)), 3L)

# The files are numbered, and each is its own batch in the log.
dir2 <- tempfile(); dir.create(dir2)
log2 <- tempfile(fileext = ".csv")
paths <- quickstatements_write(many, "wikidata-works", dir = dir2,
                               target = "wikidata", file = log2, chunk_size = 4)
expect_equal(length(paths), 3L)
expect_equal(basename(paths[1]), "wikidata-works-01.qs")
expect_true(all(file.exists(paths)))
log <- codecheck:::wikibase_log_read(log2)
expect_equal(sort(log$batch), c("wikidata-works-01", "wikidata-works-02", "wikidata-works-03"))

# Recording one part retires only that part.
quickstatements_submitted("wikidata-works-01", url = "https://example.org/1", file = log2)
expect_false(file.exists(paths[1]))
expect_true(file.exists(paths[2]))

# The duplicate-paste guard has to see a submitted part as the batch having
# been run, or a split batch would never trip it.
expect_false(is.na(codecheck:::wikidata_batch_conflict("paper", 5, log2)))

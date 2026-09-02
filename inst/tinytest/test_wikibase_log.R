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

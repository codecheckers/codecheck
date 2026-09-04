# The register shows the day of a check, never the hour; the machine-readable
# variants keep whatever precision the codecheck.yml recorded (register#219).

library("codecheck")

format_check_date_ <- getFromNamespace("format_check_date", "codecheck")
format_check_time_iso_ <- getFromNamespace("format_check_time_iso", "codecheck")
check_time_has_time_of_day_ <- getFromNamespace("check_time_has_time_of_day", "codecheck")

# --- precision detection ---

expect_true(check_time_has_time_of_day_("2020-04-13 10:00:00"))
expect_true(check_time_has_time_of_day_("2020-04-13T10:00:00Z"))
expect_false(check_time_has_time_of_day_("2020-04-13"))
expect_false(check_time_has_time_of_day_(NULL))
expect_false(check_time_has_time_of_day_(""))

# --- what readers see: the day, whatever was recorded ---

expect_equal(format_check_date_("2020-04-13 10:00:00"), "2020-04-13")
expect_equal(format_check_date_("2020-04-13"), "2020-04-13")
expect_equal(format_check_date_("2019-02-14T09:40:00Z"), "2019-02-14")
expect_true(is.na(format_check_date_(NULL)))
expect_true(is.na(format_check_date_("")))
expect_true(is.na(format_check_date_("not a date")))

# --- what machines get: the recorded precision, in ISO 8601 ---

# a wall clock with no zone comes back as written, not shifted
expect_equal(format_check_time_iso_("2020-04-13 10:00:00"), "2020-04-13T10:00:00")
expect_equal(format_check_time_iso_("2020-07-13 11:32:00"), "2020-07-13T11:32:00")
# no time of day recorded: no invented midnight
expect_equal(format_check_time_iso_("2020-04-06"), "2020-04-06")
# a value that named its own zone keeps an offset
expect_true(grepl("^2019-02-14T09:40:00", format_check_time_iso_("2019-02-14T09:40:00Z")))
expect_true(is.na(format_check_time_iso_(NULL)))
expect_true(is.na(format_check_time_iso_("")))

# The certificate JSON-LD and index.json build on these helpers; their own
# expectations live in test_schema_org_generation.R and test_cert_json_generation.R.

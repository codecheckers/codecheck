tinytest::using(ttdo)

source(system.file("extdata", "config.R", package = "codecheck"))

# Unit tests: venue_type_color() ----

# Pinned by name, so these do not shift as the register grows (register#92/#207)
expect_equal(codecheck:::venue_type_color("journal"), "#2c7a4b")
expect_equal(codecheck:::venue_type_color("community"), "#3f7fbf")
expect_equal(codecheck:::venue_type_color("conference"), "#c97a2c")
expect_equal(codecheck:::venue_type_color("institution"), "#8a4fbf")

# An unknown type is visibly neutral rather than borrowing another type's colour
expect_equal(codecheck:::venue_type_color("nonesuch"), CONFIG$VENUE_TYPE_COLOR_FALLBACK)

# Unit tests: order_type_counts() ----

unordered <- c(journal = 5L, conference = 17L, community = 4L)
expect_equal(names(codecheck:::order_type_counts(unordered)),
             c("conference", "journal", "community"))

# Ties break alphabetically, so the output is stable across renders
tied <- c(journal = 3L, community = 3L, conference = 9L)
expect_equal(names(codecheck:::order_type_counts(tied)),
             c("conference", "community", "journal"))

# Unit tests: type_breakdown_text() ----

text <- codecheck:::type_breakdown_text(codecheck:::order_type_counts(unordered),
                                        highlight = "journal")
lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
expect_equal(lines[1], "26 checks")
expect_equal(lines[2], "  conference: 17 (65%)")
expect_equal(lines[3], "▸ journal: 5 (19%)")
expect_equal(lines[4], "  community: 4 (15%)")

# A single check is not pluralised
expect_equal(strsplit(codecheck:::type_breakdown_text(c(journal = 1L)), "\n")[[1]][1],
             "1 check")

# No highlight marks nothing
expect_false(grepl("▸", codecheck:::type_breakdown_text(unordered), fixed = TRUE))

# Unit tests: codechecker_type_bar_html() (register#92) ----

expect_equal(codecheck:::codechecker_type_bar_html(integer(0)), "")
expect_equal(codecheck:::codechecker_type_bar_html(c(journal = 0L)), "")

bar <- codecheck:::codechecker_type_bar_html(unordered)

# One segment per type, in descending-count order, coloured from the map
widths <- as.numeric(regmatches(bar, gregexpr("(?<=width:)[0-9.]+", bar, perl = TRUE))[[1]])
expect_equal(length(widths), 3L)
expect_equal(round(sum(widths)), 100)
expect_true(grepl('width:65.4%;background:#c97a2c', bar, fixed = TRUE))
expect_true(grepl('width:19.2%;background:#2c7a4b', bar, fixed = TRUE))
expect_true(grepl('width:15.4%;background:#3f7fbf', bar, fixed = TRUE))

# Every segment carries the same full-breakdown tooltip as the wrapper, so no
# hover can show a partial list
titles <- regmatches(bar, gregexpr('title="[^"]*"', bar))[[1]]
expect_equal(length(titles), 4L)  # wrapper + 3 segments
expect_equal(length(unique(titles)), 1L)
expect_true(grepl("conference: 17 (65%)", titles[1], fixed = TRUE))
expect_true(grepl("journal: 5 (19%)", titles[1], fixed = TRUE))
expect_true(grepl("community: 4 (15%)", titles[1], fixed = TRUE))
# &#10; is the newline inside an attribute value that native tooltips honour
expect_true(grepl("&#10;", titles[1], fixed = TRUE))

# The screen-reader label stays a single line
expect_true(grepl('aria-label="17 conference, 5 journal, 4 community"', bar, fixed = TRUE))

# A single type is one full-width segment
solo <- codecheck:::codechecker_type_bar_html(c(community = 5L))
expect_true(grepl('width:100.0%;background:#3f7fbf', solo, fixed = TRUE))
expect_equal(length(regmatches(solo, gregexpr("<i ", solo))[[1]]), 1L)

# An unknown type still renders, in the fallback colour
unknown <- codecheck:::codechecker_type_bar_html(c(nonesuch = 2L, journal = 2L))
expect_true(grepl(CONFIG$VENUE_TYPE_COLOR_FALLBACK, unknown, fixed = TRUE))

# Unit tests: codechecker_type_donut_svg() geometry (register#207) ----

expect_equal(codecheck:::codechecker_type_donut_svg(integer(0)), "")

donut <- codecheck:::codechecker_type_donut_svg(unordered)
expect_true(grepl('viewBox="0 0 96 96"', donut, fixed = TRUE))
expect_equal(length(regmatches(donut, gregexpr("<path", donut))[[1]]), 3L)
# The dominant slice is more than half the circle, so it needs the large-arc flag
expect_true(grepl("A46 46 0 1 1", gsub("A46 46 0 ", "A46 46 0 ", donut), fixed = TRUE))

# A single type degenerates as an arc, so it is drawn as a stroked circle
solo_donut <- codecheck:::codechecker_type_donut_svg(c(community = 5L))
expect_true(grepl("<circle", solo_donut, fixed = TRUE))
expect_false(grepl("<path", solo_donut, fixed = TRUE))
expect_true(grepl('stroke="#3f7fbf"', solo_donut, fixed = TRUE))

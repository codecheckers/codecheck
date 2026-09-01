using(ttdo)

# normalize_title_for_comparison -----------------------------------------

expect_equal(
  codecheck:::normalize_title_for_comparison("A Study: Of Things!"),
  "a study of things"
)
expect_true(is.na(codecheck:::normalize_title_for_comparison(NA)))
expect_true(is.na(codecheck:::normalize_title_for_comparison("")))

# normalize_name_for_comparison -------------------------------------------

expect_equal(codecheck:::normalize_name_for_comparison("Frank O. Ostermann"), "f ostermann")
expect_equal(codecheck:::normalize_name_for_comparison("Frank Ostermann"), "f ostermann")
expect_equal(codecheck:::normalize_name_for_comparison("Philipp A. Friese"), "p friese")
expect_equal(codecheck:::normalize_name_for_comparison("Philipp Andreas Friese"), "p friese")
expect_equal(codecheck:::normalize_name_for_comparison("Cédric Van hoorickx"), "c hoorickx")
expect_equal(codecheck:::normalize_name_for_comparison("Maarten Hornikx"), "m hornikx")

# check_near_duplicate_works ------------------------------------------------

# the #133/#149 flagship case: same title, different (or missing) work key
expect_warning(
  codecheck:::check_near_duplicate_works(
    certs = c("2024-017", "2024-025"),
    work_keys = c("10.3397/in_2024_3491", NA_character_),
    titles = c(
      "Determination of a diffusion coefficient function for long rooms using a least square optimization approach",
      "Determination of a diffusion coefficient function for long rooms using a least square optimization approach"
    )
  ),
  "possible same-paper duplicate"
)

# same title, same work key: two legitimate checks of one paper, not a
# near-duplicate - must not warn
expect_silent(
  codecheck:::check_near_duplicate_works(
    certs = c("2020-001", "2020-002"),
    work_keys = c("10.1234/abc", "10.1234/abc"),
    titles = c("Same Paper", "Same Paper")
  )
)

# different titles entirely: no warning
expect_silent(
  codecheck:::check_near_duplicate_works(
    certs = c("2020-001", "2020-002"),
    work_keys = c("10.1234/abc", "10.5678/xyz"),
    titles = c("Paper One", "Paper Two")
  )
)

# check_orcid_conflicts ------------------------------------------------------

# same ORCID, materially different names (the Van hoorickx/Hornikx mix-up)
expect_warning(
  codecheck:::check_orcid_conflicts(
    certs = c("2024-017", "2024-025"),
    orcids = c("0000-0002-9671-5558", "0000-0002-9671-5558"),
    names = c("Cédric Van hoorickx", "Maarten Hornikx")
  ),
  "is recorded under different names"
)

# same ORCID, only a formatting difference: must not warn
expect_silent(
  codecheck:::check_orcid_conflicts(
    certs = c("2020-016", "2020-017"),
    orcids = c("0000-0002-9317-8291", "0000-0002-9317-8291"),
    names = c("Frank O. Ostermann", "Frank Ostermann")
  )
)

# same name, different ORCIDs (a transcription typo in one certificate)
expect_warning(
  codecheck:::check_orcid_conflicts(
    certs = c("2024-017", "2024-025"),
    orcids = c("0000-0002-9671-5558", "0000-0002-8343-6613"),
    names = c("Maarten Hornikx", "Maarten Hornikx")
  ),
  "is recorded under different ORCIDs"
)

# consistent throughout: no warning
expect_silent(
  codecheck:::check_orcid_conflicts(
    certs = c("2020-001", "2020-002"),
    orcids = c("0000-0001-8607-8025", "0000-0001-8607-8025"),
    names = c("Stephen J. Eglen", "Stephen J. Eglen")
  )
)

expect_silent(codecheck:::check_orcid_conflicts(character(0), character(0), character(0)))

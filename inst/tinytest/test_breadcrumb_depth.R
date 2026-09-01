using(ttdo)

source(system.file("extdata", "config.R", package = "codecheck"))

# calculate_breadcrumb_base_path derives depth from output_dir when present,
# which a plain filter/subcat shape can't express for a DOI-nested work page.

expect_equal(codecheck:::calculate_breadcrumb_base_path(NA, list()), ".")

# existing shapes still resolve correctly via output_dir
expect_equal(
  codecheck:::calculate_breadcrumb_base_path("venues", list(
    is_reg_table = TRUE, subcat = "journal", output_dir = "docs/venues/journals/gigascience/"
  )),
  "../../.."
)
expect_equal(
  codecheck:::calculate_breadcrumb_base_path("codecheckers", list(
    is_reg_table = TRUE, output_dir = "docs/codecheckers/0000-0001-8607-8025/"
  )),
  "../.."
)
expect_equal(
  codecheck:::calculate_breadcrumb_base_path("venues", list(
    is_reg_table = FALSE, subcat = "journal", output_dir = "docs/venues/journals/"
  )),
  "../.."
)
expect_equal(
  codecheck:::calculate_breadcrumb_base_path("venues", list(
    is_reg_table = FALSE, output_dir = "docs/venues/"
  )),
  ".."
)

# a work page's DOI can carry an extra "/" segment, going one level deeper
# than any existing filter shape
expect_equal(
  codecheck:::calculate_breadcrumb_base_path("works", list(
    is_reg_table = TRUE, output_dir = "docs/works/10.1093/gigascience/giaa026/"
  )),
  "../../../.."
)
expect_equal(
  codecheck:::calculate_breadcrumb_base_path("works", list(
    is_reg_table = TRUE, output_dir = "docs/works/10.31222/osf.io/a8rmu/"
  )),
  "../../../.."
)

# falls back to the filter-shape heuristic when output_dir is absent
expect_equal(
  codecheck:::calculate_breadcrumb_base_path("codecheckers", list(is_reg_table = TRUE)),
  "../.."
)

# generate_breadcrumb(): a venue *type* overview page (e.g. /venues/journals/)
# is not a reg table itself but does carry a subcat, one level below the top
# venues overview (neither is_reg_table nor subcat) and one level above an
# individual venue page (is_reg_table + subcat). Previously the type overview
# fell into the same branch as the top overview and always rendered a bare,
# non-linked "Venues" as the active crumb, dropping "Journals" entirely.
type_overview_html <- codecheck:::generate_breadcrumb(
  "venues", list(is_reg_table = FALSE, subcat = "journal"), ".."
)
expect_true(grepl('<a href="../venues/index.html">Venues</a>', type_overview_html, fixed = TRUE))
expect_true(grepl('breadcrumb-item active" aria-current="page">Journals</li>', type_overview_html, fixed = TRUE))

# the top venues overview itself is unaffected - "Venues" stays the active,
# non-linked crumb
top_overview_html <- codecheck:::generate_breadcrumb("venues", list(is_reg_table = FALSE), ".")
expect_true(grepl('breadcrumb-item active" aria-current="page">Venues</li>', top_overview_html, fixed = TRUE))
expect_false(grepl("Journals", top_overview_html, fixed = TRUE))

# an individual venue page still shows the full Venues > Journals > <venue> trail
venue_page_html <- codecheck:::generate_breadcrumb(
  "venues", list(is_reg_table = TRUE, subcat = "journal", name = "GigaByte"), "../.."
)
expect_true(grepl('<a href="../../venues/index.html">Venues</a>', venue_page_html, fixed = TRUE))
expect_true(grepl('<a href="../../venues/journals/index.html">Journals</a>', venue_page_html, fixed = TRUE))
expect_true(grepl('active" aria-current="page">GigaByte</li>', venue_page_html, fixed = TRUE))

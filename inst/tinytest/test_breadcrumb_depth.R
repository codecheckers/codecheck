using(ttdo)

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

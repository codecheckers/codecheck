#' Function for adding repository links in the register table for CSV files.
#'
#' @param register_table The register table
#' @return Register table with Repository Link column added
add_repository_links_csv <- function(register_table) {
  register_table$`Repository Link` <- sapply(
    X = register_table$Repository,
    FUN = function(repository) {
      spec <- parse_repository_spec(repository)
      if (spec[["type"]] == "github") {
        paste0(CONFIG$HYPERLINKS[["github"]], spec[["repo"]])
      } else if (spec[["type"]] == "osf") {
        paste0(CONFIG$HYPERLINKS[["osf"]], spec[["repo"]])
      } else if (spec[["type"]] == "gitlab") {
        paste0(CONFIG$HYPERLINKS[["gitlab"]], spec[["repo"]])
      } else if (spec[["type"]] == "zenodo") {
        paste0(CONFIG$HYPERLINKS[["zenodo"]], spec[["repo"]])
      } else {
        repository
      }
    }
  )
  return(register_table)
}

#' Set "Title" and "Paper reference" columns for CSV files
#'
#' Extracts plain text title and paper reference URL from the preprocessed register table.
#' If the table has a "Paper Title" column (hyperlinked), extracts from that.
#' Otherwise, fetches from codecheck.yml files.
#'
#' @param register_table The register table
#' @return Updated register table including "Title" and "Paper reference" columns
set_paper_title_references_csv <- function(register_table){
  titles <- c()
  references <- c()

  # Check if Paper Title column exists
  has_paper_title <- "Paper Title" %in% names(register_table)

  for (i in seq_len(nrow(register_table))) {
    if (has_paper_title) {
      paper_title <- register_table[i, ]$`Paper Title`

      # Extract plain text and URL from markdown link [Title](URL)
      # Pattern: [text](url)
      if (!is.null(paper_title) && !is.na(paper_title) && grepl("\\[.*\\]\\(.*\\)", paper_title)) {
        # Extract title: everything between [ and ]
        title <- sub("\\[(.*)\\]\\(.*\\)", "\\1", paper_title)
        # Extract reference: everything between ( and )
        reference <- sub("\\[.*\\]\\((.*)\\)", "\\1", paper_title)
      } else {
        # No hyperlink, use as-is for title and NA for reference
        title <- paper_title
        reference <- NA
      }
    } else {
      # Fetch from codecheck.yml
      config_yml <- get_codecheck_yml(register_table[i, ]$Repository)

      title <- NA
      reference <- NA
      if (!is.null(config_yml)) {
        title <- config_yml$paper$title
        reference <- config_yml$paper$reference
      }
    }

    titles <- c(titles, title)
    references <- c(references, reference)
  }

  register_table$Title <- stringr::str_trim(titles)
  register_table$`Paper reference` <- stringr::str_trim(references)

  return(register_table)
}

#' Creates filtered CSV files from a register based on specified filters.
#'
#' The function processes the preprocessed register table by applying filters specified in `filter_by`.
#' For "codecheckers", a temporary CSV is loaded and processed as the original register.csv
#' does not have the codechecker column.
#' The register is then grouped by the filter column, and for each group, a CSV file is generated.
#' CSV files include all fields that JSON files have (Repository Link, Title, Paper reference).
#'
#' @param register_table The preprocessed register table with enriched columns.
#' @param filter_by List of filters to apply (e.g., "venues", "codecheckers").
#'
#' @importFrom utils write.csv
#'
create_filtered_reg_csvs <- function(register_table, filter_by){
  for (filter in filter_by){
    if (filter == "codecheckers"){
      # Using the temporary codechecker register (already preprocessed)
      register_table <- read.csv(CONFIG$DIR_TEMP_REGISTER_CODECHECKER, as.is = TRUE)
      # Once the temp_register is loaded, we can remove it
      file.remove(CONFIG$DIR_TEMP_REGISTER_CODECHECKER)

      # Splitting the comma-separated strings into lists
      register_table$Codechecker <- strsplit(register_table$Codechecker, ",")

      # Unnesting the files
      register_table <- register_table %>% tidyr::unnest(Codechecker)
      register_table$Codechecker <- unlist(register_table$Codechecker)

      # Deduplicate NA codecheckers: if a certificate has multiple codecheckers
      # without ORCID (all marked as NA), it should only appear once in the NA list
      # We keep one row per unique combination of Certificate ID and Codechecker
      # This ensures each certificate appears only once in the NA codechecker page
      # even if multiple codecheckers lack ORCID (fixes codecheckers/register#153)
      # Note: We use Certificate column here (not Certificate ID) as it may not exist yet
      register_table <- register_table %>%
        distinct(Certificate, Codechecker, .keep_all = TRUE)
    }

    # Enrich register with additional fields (matching JSON output)
    # Add Repository Link column
    register_table <- add_repository_links_csv(register_table)
    # Add Title and Paper reference columns (extracted from hyperlinked Paper Title)
    register_table <- set_paper_title_references_csv(register_table)

    filter_col_name <- CONFIG$FILTER_COLUMN_NAMES[[filter]]

    # Creating groups of csvs
    # Not using the nesting functionality since we want to keep the same columns
    grouped_registers <- register_table %>%
      group_by(across(all_of(filter_col_name)))

    # Split into a list of data frames
    filtered_register_list <- grouped_registers %>% group_split()

    # Get the group names (keys) based on the filter names
    register_keys <- grouped_registers %>% group_keys()

    # Iterating through each group and generating csv
    for (i in seq_along(filtered_register_list)) {
      # Retrieving the register and its key
      register_key <- register_keys[[filter_col_name]][i]
      filtered_register <- filtered_register_list[[i]]
      table_details <- generate_table_details(register_key, filtered_register, filter)
      filtered_register <- filter_and_drop_register_columns(filtered_register, filter, file_type = "csv")
      output_dir <- paste0(table_details[["output_dir"]], "register.csv")
      write.csv(filtered_register, output_dir, row.names=FALSE)
    }
  }
}

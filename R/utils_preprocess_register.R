#' Function for clearing the register cache
#'
#' @return 0 for success, 1 for failure, invisibly (see `unlink`)
#'
#' @author Daniel Nuest
#' @importFrom R.cache getCacheRootPath
#' @export
register_clear_cache <- function() {
  path <- R.cache::getCacheRootPath()
  message("Deleting cache path ", path)
  unlink(path, recursive = TRUE)
}

#' Function for adding clickable links to the paper for each entry in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table
add_paper_links <- function(register_table, register){
  list_hyperlinks <- c()

  # Looping over the entries in the register
  for (i in seq_len(nrow(register))) {
    # Retrieving the link to the paper 
    config_yml <- get_codecheck_yml(register[i, ]$Repo)
    paper_link <- config_yml[["paper"]][["reference"]]
    paper_title <- config_yml[["paper"]][["title"]]

    # Removing new lines from paper title and link
    paper_title <- gsub("\n", " ", paper_title)
    paper_link <- gsub("\n$", "", paper_link)
    
    #cat("Adding paper link for ", paper_title, " with link ", paper_link, " for ", register[i, ]$Repo, "\n")
    # Checking if there is a valid url for the paper. If not we just add the title as it is
    url_regex <- "^https?://"
    if (!grepl(url_regex, paper_link)){
      warning("The codecheck_yml's paper reference is not a valid url.")
      list_hyperlinks <- c(list_hyperlinks, paper_title)
    }

    # If we have a valid url we add hyperlink
    else{
      paper_hyperlink <- paste0(
        "[",
        paper_title,
        "](",
        paper_link,
        ")"
      )
      list_hyperlinks <- c(list_hyperlinks, paper_hyperlink)
    }
  }
  # Creating a new "Paper Title" column and moving it next to the "Repository" column
  register_table <- register_table %>% 
    mutate(`Paper Title` = list_hyperlinks) %>%
    relocate(`Paper Title`, .after = Repository)
  return(register_table)
}

#' Function for adding report URLs for each entry in the register table.
#'
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table with Report column containing plain URLs
add_report_links <- function(register_table, register) {

  reports <- c()

  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml(register[i, ]$Repo)

    report <- NA
    if (!is.null(config_yml)) {
      report <- config_yml$report
    }

    reports <- c(reports, report)
  }
  register_table$Report <- reports
  return(register_table)
}

#' Function for adding clickable links to the issue number of each report in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table
add_issue_number_links <- function(register_table, register) {
  register_table$Issue <- sapply(
    X = register$Issue,
    FUN = function(issue_id) {
      if (!is.na(issue_id)) {
        paste0(
          "[",
          issue_id,
          "](",
          CONFIG$HYPERLINKS[["codecheck_issue"]],
          issue_id, ")"
        )
      } else {
        issue_id
      }
    }
  )
  return(register_table)
}

#' Function for adding check time to each report in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table
add_check_time <- function(register_table, register) {
  check_times <- c()

  # Looping over the entries in the register
  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml(register[i, ]$Repo)

    check_time <- NA
    if (!is.null(config_yml)) {
      check_time <- config_yml$check_time
    }

    check_times <- c(check_times, check_time)
  }
  check_times <- parsedate::parse_date(check_times)
  register_table$`Check date` <- format(check_times, "%Y-%m-%d")

  return(register_table)
}

#' Function for adding codechecker to each report in the register table.
#' 
#' @param register_table The register table
#' @param register The register from the register.csv file
#' @return The adjusted register table
add_codechecker <- function(register_table, register) {
  codecheckers <- vector("list", length = nrow(register))

  # Looping over the entries in the register
  for (i in seq_len(nrow(register))) {
    config_yml <- get_codecheck_yml(register[i, ]$Repo)

    codechecker_ids <- c()
    if (!is.null(config_yml)  && !is.null(config_yml$codechecker)) {

      for (codechecker in config_yml$codechecker) {
        if(is.null(codechecker$name)) {
          stop("Codechecker name is missing in ", config_yml$certificate)
        }

        # Use ORCID as identifier if available
        if (!is.null(codechecker$ORCID) && codechecker$ORCID != "") {
          if (!(codechecker$ORCID %in% names(CONFIG$DICT_ORCID_ID_NAME))) {
            CONFIG$DICT_ORCID_ID_NAME[codechecker$ORCID] <- codechecker$name
          }
          codechecker_ids <- c(codechecker_ids, codechecker$ORCID)
        } else {
          # Fall back to GitHub username for codecheckers without ORCID
          github_username <- get_github_handle_by_name(codechecker$name)

          if (!is.null(github_username)) {
            # Use GitHub username directly as identifier
            if (!(github_username %in% names(CONFIG$DICT_GITHUB_USERNAME_NAME))) {
              CONFIG$DICT_GITHUB_USERNAME_NAME[github_username] <- codechecker$name
            }
            codechecker_ids <- c(codechecker_ids, github_username)
          } else {
            # Use "NA" as identifier for codecheckers without ORCID or GitHub username
            codechecker_ids <- c(codechecker_ids, "NA")
            warning("codechecker ORCID and GitHub username missing for ", codechecker$name, " in ", config_yml$certificate)
          }
        }
      }
    } else {
      warning("codechecker not found in record ", toString(register[i, ]))
    }

    codecheckers[[i]] <- codechecker_ids
  }
  register_table$`Codechecker` <- codecheckers
  return(register_table)
}

#' Function for adding clickable links to the paper for each entry in the register table and add certificate identifier and link as extra columns
#' 
#' @param register_table The register table to be adjusted.
#' @return The adjusted register table with clickable Certificate links and new columns for certificate identifier and certificate URL
add_cert_links <- function(register_table){
  ids <- c()
  links <- c()
  
  # Looping over the entries in the register
  for (i in seq_len(nrow(register_table))) {

    cert_id <- register_table[i, ]$Certificate
    cert_link <- paste0(CONFIG$HYPERLINKS[["certs"]], cert_id, "/")
    
    # Constructing the hyperlink
    hyperlink <- paste0("[", cert_id, "](", cert_link, ")")
    register_table[i, ]$Certificate <- hyperlink
    
    ids <- c(ids, cert_id)
    links <- c(links, cert_link)
  }

  register_table$`Certificate ID` <- ids
  register_table$`Certificate Link` <- links
  
  return(register_table)
}

#' Creates a temporary CSV register with a "Codechecker" column.
#' 
#' The function flattens the "Codechecker" column and saves the resulting table 
#' as a temporary CSV file. This tempeorary CSV is needed to filter the registers b
#' by codecheckers.
#' 
#' @param register_table The register table with a "Codechecker" column.
#' 
#' @importFrom utils write.csv
#' 
create_temp_register_with_codechecker <- function(register_table){
  # Flatten the Codechecker column (convert list elements to comma-separated strings)
  # This is done since jsons cannot handle list columns directly
  register_table$Codechecker <- sapply(register_table$Codechecker, function(x) paste(x, collapse = ","))
  write.csv(register_table, CONFIG$DIR_TEMP_REGISTER_CODECHECKER)
}

#' Function for preprocessing the register to create and return the preprocessed register table.
#' 
#' @param register The register.
#' @param filter_by The filter (if applicable).
#' 
#' @return The preprocessed register table
preprocess_register <- function(register, filter_by) {
    register_table <- register

    if ("codecheckers" %in% filter_by){
      # Adding the codechecker column which is needed for filtering by codechecker later
      register_table <- add_codechecker(register_table, register)
    }
    register_table <- add_cert_links(register_table)
    register_table <- add_report_links(register_table, register)
    register_table <- add_issue_number_links(register_table, register)
    register_table <- add_check_time(register_table, register)
    register_table <- add_paper_links(register_table, register)

    # Create temp register CSV after all enrichment is complete
    # This ensures the CSV has all enriched columns for codechecker filtering
    if ("codecheckers" %in% filter_by){
      create_temp_register_with_codechecker(register_table)
    }

    return(register_table)
}

#' Function to load the markdown table
#' 
#' @param template_path The path to the markdown template
#' @return The markdown table template
load_md_template <- function(template_path){
  if (!file.exists(template_path)){
    stop("No register table template found")
  }

  md_table <- readLines(template_path)
  return(md_table)
}

#' Function to add the markdown title based on the specific register table name.
#' 
#' @param markdown_table The markdown template where the title needs to be added
#' @param register_table_name The name of the register table
#'
#' @return The modified markdown table
add_markdown_title <- function(filter, md_table, register_table_name){
  if (filter == "none"){
    title <- "CODECHECK Register"
  }
  
  # For codechecker filtered registers we show the name and the ORCID ID
  else if (filter == "codecheckers") {
    author_name <- CONFIG$DICT_ORCID_ID_NAME[register_table_name]
    orcid_id <- register_table_name
    title <- paste0("Codechecks by ", author_name, " (", orcid_id,")")
  }
  
  # For venue filtered registers we display the venue name in the title.
  else if (filter == "venues"){
    title <- paste("CODECHECK Register for", register_table_name)
  }

  md_table <- gsub("\\$title\\$", title, md_table)
  return(md_table)
}

#' Function for adding repository links in the register table for the creation of the markdown file.
#' 
#' @param register_table The register table
#' @return Register table with adjusted repository links
add_repository_links_md <- function(register_table) {
  register_table$Repository <- sapply(
    X = register_table$Repository,
    FUN = function(repository) {
      spec <- parse_repository_spec(repository)
      if (!any(is.na(spec))) {
        urrl <- "#"

        switch(spec["type"],
          "github" = {
            urrl <- paste0("https://github.com/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },
          "osf" = {
            urrl <- paste0("https://osf.io/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },
          "gitlab" = {
            urrl <- paste0("https://gitlab.com/", spec[["repo"]])
            paste0("[", spec[["repo"]], "](", urrl, ")")
          },

          # Type is none of the above
          {
            repository
          }
        )
      } else {
        repository
      }
    }
  )
  return(register_table)
}

#' Renders register md for a single register_table
#' 
#' @param filter The filter
#' @param register_table The register table
#' @param register_table_name The register table name
render_register_md <- function(filter, register_table, register_table_name, for_html_file=FALSE) {
  # If we are rendering md for html file, we do not need to add repo links
  if (for_html_file == FALSE){
    register_table <- add_repository_links_md(register_table)
  }
  # Fill in the content
  md_table <- load_md_template(CONFIG$MD_TEMPLATE)

  markdown_content <- capture.output(kable(register_table, format = "markdown"))
  md_table <- add_markdown_title(filter, md_table, register_table_name)
  md_table <- gsub("\\$content\\$", paste(markdown_content, collapse = "\n"), md_table)

  # Adjusting the column widths
  md_table <- unlist(strsplit(md_table, "\n", fixed = TRUE))
  # Determining which line to add the md column widths in
  alignment_line_index <- grep("^\\|:---", md_table)
  md_table[alignment_line_index] <- CONFIG$MD_COLUMNS_WIDTHS

  # Determining the directory and saving the file
  output_dir <- get_output_dir(filter, register_table_name)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
  }

  # If rendering md for html file we create a temp file
  if (for_html_file){
    output_dir <- paste0(output_dir, "temp.md")
  }

  else{
    output_dir <- paste0(output_dir, "register.md")
  }

  writeLines(md_table, output_dir)
}

#' Renders register mds for a list of register tables
#' 
#' @param list_register_table List of register tables
render_register_mds <- function(list_register_tables){
  for (filter in names(list_register_tables)){
    for (register_table_name in names(list_register_tables[[filter]])){
      register_table <- list_register_tables[[filter]][[register_table_name]]
      render_register_md(filter, register_table, register_table_name)
    }
  }
}

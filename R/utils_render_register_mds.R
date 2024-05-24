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

#' Function to adjust the markdown title based on the specific register table name.
#' 
#' @param markdown_table The markdown template where the title needs to be adjusted
#' @param register_table_name The name of the register table
#'
#' @return The modified markdown table
adjust_markdown_title <- function(md_table, register_table_name){

  if (register_table_name != "Original"){
    title_addition <- ""
  }
  
  else {
    title_addition <- paste("for", register_table_name)
  }

  md_table <- gsub("\\$title_addition\\$", title_addition, md_table)
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

# Helper function to process each table and convert it to markdown format
render_register_md <- function(filter, register_table, register_table_name, md_table, md_columns_widths, is_temp_file=FALSE) {
  # Fill in the content
  markdown_content <- capture.output(kable(register_table, format = "markdown"))
  
  md_table <- adjust_markdown_title(md_table, register_table_name)
  md_table <- gsub("\\$content\\$", paste(markdown_content, collapse = "\n"), md_table)

  # Adjusting the column widths
  md_table <- unlist(strsplit(md_table, "\n", fixed = TRUE))
  # Determining which line to add the md column widths in
  alignment_line_index <- grep("^\\|:---", md_table)
  md_table[alignment_line_index] <- md_columns_widths

  # Determining the directory and saving the file
  output_dir <- get_output_dir(filter, register_table_name)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = TRUE)
  }

  if (is_temp_file){
    output_file_path <- paste0(output_dir, "temp.md")
  }

  else{
    output_file_path <- paste0(output_dir, "register.md")
  }

  writeLines(md_table, output_file_path)
}

render_register_mds <- function(list_register_tables, md_template){
  md_table <- load_md_template(md_template)
  for (filter in names(list_register_tables)){
    for (register_table_name in names(list_register_tables[[filter]]))
      register_table <- list_register_tables[[filter]][[register_table_name]]
      render_register_md(filter, register_table, register_table_name, md_table, md_columns_widths)
  }
}

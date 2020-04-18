##' Create template files for the codecheck process.
##'
##' This function simply creates some template files to help start the
##' codecheck process.  If either ./codecheck.yml or codecheck/ exists then
##' it assumes you have already started codechecking, and so will not copy any
##' files across.
##' @title Create template files for the codecheck process.
##' @return Nothing
##' @author Stephen J. Eglen
create_codecheck_files <- function() {
  if (file.exists("codecheck.yml"))
    error("codecheck.yml already exists, so stopping.")
  if (dir.exists("codecheck"))
    error("codecheck folder exists, so stopping.")
  templates <- system.file("extdata", "templates", package="codecheck")
  file.copy(file.path(templates, "codecheck.yml"), ".")
  file.copy(file.path(templates, "codecheck"), ".", recursive=TRUE)
}

##' Return the metadata for the codecheck project in root folder of project
##'
##' 
##' @title Return the metadata for the codecheck project in root folder of project
##' @param root Path to the root folder of the project.
##' @return A list containing the metadata found in the codecheck.yml file
##' @author Stephen Eglen
codecheck_metadata <- function(root) {
  read_yaml( file.path(root, "codecheck.yml") )
}


##' Copy manifest files into the root/codecheck/outputs folder; return manifest.
##'
##' The metadata should specify the manifest -- the files to copy into the
##' codecheck/oututs folder.  Each of the files in the manifest is copied into
##' the destination directory and then the manifest is returned as a dataframe.
##' @title 
##' @param root - Path to the root folder of the proejct.
##' @param metadata - the codecheck metadata list.
##' @return A dataframe containing one row per manifest file.
##' @author Stephen Eglen
.copy_manifest_files <- function(root, metadata) {
}



## latex summary of metadata

## Temporary hack to make URL
.url_it = function(url) {
  url = sub("<", "\\\\url{", url)
  url = sub(">", "}", url)
  url
}

.authors <- function(y) {
  authors = y$paper$authors
  num_authors = length(authors)
  for (i in 1:num_authors)
    if (i==1) {
      author_list = authors[[i]]
    } else {
      author_list = paste(author_list, authors[[i]], sep=', ')
    }
  author_list
}

.codecheckers <- function(y) {
  ## TODO: this doesn't handle multiple codecheckers
  ## TODO: should convert to url properly.
  num_checkers = length(y$codechecker)
  checkers = ""
  for (i in 1:num_checkers) {
    checker = y$codechecker[[i]]
    orcid = checker$ORCID
    p = paste(checker$name,
              sprintf('\\orcidicon{%s} ', orcid))
    checkers=paste(checkers, p, sep=" ")
  }
  checkers
}
##' Print a latex table to summarise CODECHECK metadata
##'
##' Format a latex table that summarises the main CODECHECK metadata,
##' excluding the MANIFEST.
##' @title Print a latex table to summarise CODECHECK metadata
##' @param metadata - the codecheck metadata list.
##' @return The latex table, suitable for including in the Rmd
##' @author Stephen Eglen
latex_summary_of_metadata <- function(metadata) {
  summary_entries = list(
    "Title" =            metadata$paper$title,
    "Authors" =          .authors(metadata),
    "Reference" =        .url_it(metadata$paper$reference),
    "Codechecker" =      .codecheckers(metadata),
    "Date of check" =   metadata$check_time,
    "Summary" =         metadata$summary,
    "Repository" =      .url_it(metadata$repository))
  summary_df = data.frame(Item=names(summary_entries),
                          Value=unlist(summary_entries, use.names=FALSE))

  print(xtable(summary_df, align=c('l', 'l', 'p{10cm}'),
             caption='CODECHECK summary'),
      include.rownames=FALSE,
      include.colnames=TRUE,
      sanitize.text.function = function(x){x},
      comment=FALSE)
}

######################################################################
## Code for woking with zenodo records.

.create_zenodo_record <- function(zen) {
}

.set_zenodo_metadata <- function(zen, metadata) {
}

.set_zenodo_certificate <- function(zen, certificate="codecheck.pdf") {
}

## We deliberately do not provide a function to publish the certificate.
## You should go check it yourself.

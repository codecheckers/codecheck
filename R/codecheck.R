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

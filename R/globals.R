#' @importFrom stats median setNames
#' @keywords internal
"_PACKAGE"

# Declare global variables used in NSE (non-standard evaluation)
# to avoid R CMD check NOTEs about "no visible binding for global variable"
utils::globalVariables(c(
  # Column names used in data.frame/dplyr operations
  "Certificate",
  "Certificate ID",
  "Check date",
  "codechecker_name",
  "venue_label"
))

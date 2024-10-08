% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_render_table_codecheckers.R
\name{create_all_codecheckers_table}
\alias{create_all_codecheckers_table}
\title{Create Codecheckers Table}
\usage{
create_all_codecheckers_table(register_table)
}
\arguments{
\item{register_table}{The register table}
}
\value{
A list with a single element, the codechecker table
}
\description{
Processes the register table to create a new table of distinct codecheckers. 
The resulting table has codechecker name, codechecker ID and no. of codechecks column
}

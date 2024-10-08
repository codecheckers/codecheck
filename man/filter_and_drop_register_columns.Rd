% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_render_register_general.r
\name{filter_and_drop_register_columns}
\alias{filter_and_drop_register_columns}
\title{Filter and Drop Columns from Register Table}
\usage{
filter_and_drop_register_columns(register_table, filter, file_type)
}
\arguments{
\item{register_table}{The register table}

\item{filter}{A string specifying the filter to apply (e.g., "venues", "codecheckers").}

\item{file_type}{The type of file we need to render the register for. 
The columns to keep depend on the file type}
}
\value{
The filtered register table with only the necessary columns retained.
}
\description{
This function filters and drops columns from the register table based on the 
specified filter type. Removes any columns that are flagged for dropping 
based on the filter and CONFIG$FILTER_COLUMN_NAMES_TO_DROP
}

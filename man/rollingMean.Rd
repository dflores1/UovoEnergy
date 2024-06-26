% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/conn.R
\name{rollingMean}
\alias{rollingMean}
\title{Calculates a rolling mean over a given numeric column}
\usage{
rollingMean(.data, .column, .window)
}
\arguments{
\item{.data}{The data tibble}

\item{.column}{What numeric column should be recalculated}

\item{.window}{Number of days for the rolling mean}
}
\value{
A new data tibble
}
\description{
Per day plot shapes are usually very jagged.
This functions smoothes them over a period of days
}

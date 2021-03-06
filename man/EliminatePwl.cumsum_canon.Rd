% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/eliminate_pwl.R
\name{EliminatePwl.cumsum_canon}
\alias{EliminatePwl.cumsum_canon}
\title{EliminatePwl canonicalizer for the cumulative sum atom}
\usage{
EliminatePwl.cumsum_canon(expr, args)
}
\arguments{
\item{expr}{An \linkS4class{Expression} object}

\item{args}{A list of \linkS4class{Constraint} objects}
}
\value{
A canonicalization of the piecewise-lienar atom
constructed from a cumulative sum atom where the objective
is Y that is of the same dimension as the matrix of the expression
and the constraints consist of various row constraints
}
\description{
EliminatePwl canonicalizer for the cumulative sum atom
}

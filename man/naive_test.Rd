% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/testing.R
\name{naive_test}
\alias{naive_test}
\title{naive_test}
\usage{
naive_test(ctrl_data, cancer_data, quant, factor)
}
\arguments{
\item{ctrl_data}{A matrix with genes expressions in controls for all the patients.}

\item{cancer_data}{A matrix with dysregulated genes expressions for all the patients.}

\item{quant}{The quantile of the control genes expression, quantile(c(quant, 1-quant)).}

\item{factor}{The factor for the quantile. The D limit will be quantmin/factor, and the U limit quantmax*factor.}
}
\value{
This function return a list with two vectors :
D, with TRUE for genes down-regulated
U, with TRUE for genes up-regulated.
}
\description{
This function makes the test of the dysregulation with a naive method based on the quantiles of
the normal distribution of each gene.
}
\examples{
simulation = ctrl_data[,ncol(ctrl_data)-3 : ncol(ctrl_data)]
simulation = simplified_simulation(simulation, fraction = 0.3, threshold = 60)
ctrl_data = ctrl_data[,-ncol(ctrl_data)-3:ncol(ctrl_data)]
quantile_gene(ctrl_data, simulation$simulated_data, quant = 0.03, factor = 1.4)

}

library(parallel)
ncores <- min(c(8, parallel::detectCores()))

cran_packages <- c(
    "R.utils",
    "ape",
    "argparse",
    "dplyr",
    "lattice",
    "latticeExtra",
    "reshape2",
    "rmarkdown",
    "readr",
    "tidyr"
)

install.packages(
    cran_packages,
    repos="http://cran.us.r-project.org",
    Ncpus=ncores,
    clean=TRUE)

bioc_packages <- c(
    "devtools",
    "phyloseq",
    "qrqc"
)

## source("https://bioconductor.org/biocLite.R")
biocLite(
    bioc_packages,
    suppressUpdates=TRUE,
    Ncpus=ncores,
    clean=TRUE)

dada2_version = '630ef9ac993267eda7224ba5326600c3aaff8a6f' ## version 1.8
devtools::install_github("benjjneb/dada2", ref=dada2_version)

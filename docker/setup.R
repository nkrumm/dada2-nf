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

dada2_version = '553008d286895af90e9d0a734c7210c1bc597b8c' ## version 1.6
devtools::install_github("benjjneb/dada2", ref=dada2_version)

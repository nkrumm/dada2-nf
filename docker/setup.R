library(parallel)
ncores <- min(c(8, parallel::detectCores()))

cran_packages <- c(
    "argparse",
    "lattice",
    "latticeExtra",
    "rmarkdown",
    "R.utils",
    "tidyr"
)

install.packages(
    cran_packages,
    repos="http://cran.us.r-project.org",
    Ncpus=ncores,
    clean=TRUE)

bioc_packages <- c(
    "devtools",
    "qrqc"
)

## source("https://bioconductor.org/biocLite.R")
biocLite(
    bioc_packages,
    suppressUpdates=TRUE,
    Ncpus=ncores,
    clean=TRUE)

dada2_version = 'd57ccf5e22c8e709bf625a033dfa25561cbd392f' ## version 1.4.1
devtools::install_github("benjjneb/dada2", ref=dada2_version)

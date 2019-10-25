library(parallel)
ncores <- min(c(8, parallel::detectCores()))

dada2_commit <- Sys.getenv('DADA2_COMMIT')
if(nchar(dada2_commit) == 0){
  stop('the environment variable DADA2_COMMIT must be set')
}

#    "reshape2",

cran_packages <- c(
    "argparse"
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

BiocManager::install(bioc_packages)
devtools::install_github("benjjneb/dada2", ref=dada2_commit)

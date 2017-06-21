packages <- c("argparse", "lattice", "latticeExtra", "tidyr", "rmarkdown")
install.packages(
    packages,
    repos="http://cran.us.r-project.org",
    dependencies=TRUE,
    Ncpus=2)

source("https://bioconductor.org/biocLite.R")
biocLite(c("ShortRead", "devtools", "qrqc"), suppressUpdates=FALSE)
dada2_version = 'd57ccf5e22c8e709bf625a033dfa25561cbd392f' ## version 1.4.1
devtools::install_github("benjjneb/dada2", ref=dada2_version)

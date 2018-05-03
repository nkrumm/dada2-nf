fastq_files <- function(fastqs){
  fnFs <- fastqs[grepl("_R1_", fastqs)] # Just the forward read files
  fnRs <- fastqs[grepl("_R2_", fastqs)] # Just the reverse read files

  stopifnot(length(fnFs) > 0 & length(fnRs) > 0)
  stopifnot(all(file.exists(fnFs)) & all(file.exists(fnRs)))

  sample.names <- sapply(strsplit(basename(fnFs), "_"), '[', 1)

  ## confirm that all forward and reverse reads are paired
  stopifnot(all(sample.names == sapply(strsplit(basename(fnRs), "_"), '[', 1)))

  list(
      fnFs=setNames(fnFs, sample.names),
      fnRs=setNames(fnRs, sample.names),
      sample.names=sample.names
  )
}

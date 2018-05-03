#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(argparse, quietly = TRUE))

## provides fastq_files()
source(file.path(
    normalizePath(dirname(gsub('--file=', '', grep('--file', commandArgs(), value=TRUE)))),
    'dada2_common.R'))

main <- function(arguments){
  parser <- ArgumentParser()
  parser$add_argument('infile')
  parser$add_argument('--batch')
  parser$add_argument('-o', '--outfile')
  args <- parser$parse_args(arguments)

  load(args$infile)

  ## 'merged' is expected to be a list of data.frames, one per
  ## specimen. When there is only one specimen, a bare data.frame is
  ## returned. Convert this to a list of length one for consistency.
  if(is.data.frame(merged)){
    merged <- list(merged)
  }

  overlaps <- do.call(rbind, lapply(merged, '[', c('abundance', 'nmatch')))

  if(nrow(overlaps) > 0){
    tab <- aggregate(abundance ~ nmatch, overlaps, sum)
    tab$batch <- if(is.null(args$batch)){ '' }else{ args$batch }
  }else{
    tab <- data.frame(nmatch=numeric(0), abundance=numeric(0), batch=character(0))
  }
  write.csv(tab, file=args$outfile, row.names=FALSE)

}

main(commandArgs(trailingOnly=TRUE))
## invisible(warnings())

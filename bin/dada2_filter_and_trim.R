#!/usr/bin/env Rscript

## provides fastq_files()
source(file.path(
    normalizePath(dirname(gsub('--file=', '', grep('--file', commandArgs(), value=TRUE)))),
    'dada2_common.R'))

suppressPackageStartupMessages(library(argparse, quietly = TRUE))
suppressPackageStartupMessages(library(dada2, quietly = TRUE))

main <- function(arguments){
  parser <- ArgumentParser()
  parser$add_argument('file_list', help='file listing fastq inputs')
  parser$add_argument('--filt-path', default='filtered',
                      help='path containing filtered output')
  parser$add_argument('--f-trunc', type='integer', required=TRUE,
                      help='position at which to truncate forward reads')
  parser$add_argument('--r-trunc', type='integer', required=TRUE,
                      help='position at which to truncate reverse reads')
  parser$add_argument('--trim-left', type='integer', required=TRUE,
                      help='position at which to left-trim both F and R reads')
  parser$add_argument('--max-ee', type='integer',
                      help='After truncation, reads with higher than maxEE "expected errors" will be discarded (default is no filtering using this parameter)')
  parser$add_argument('--truncq', type='integer', metavar='N', default=2,
                      help='truncare reads at the first instance of a quality score <= N')

  args <- parser$parse_args(arguments)

  fastqs <- fastq_files(scan(args$file_list, what='character'))
  filt_path <- args$filt_path
  trim_left <- rep(args$trim_left, 2)
  if(!file_test("-d", filt_path)){ dir.create(filt_path) }
  maxEE <- if(is.null(args$max_ee)){ Inf }else{ args$max_ee}
  truncQ <- args$truncq

  with(fastqs, {
    filtFs <- file.path(filt_path, paste0(sample.names, "_R1_filt.fastq.gz"))
    filtRs <- file.path(filt_path, paste0(sample.names, "_R2_filt.fastq.gz"))

    for(i in seq_along(fnFs)) {
      dada2::fastqPairedFilter(fn=c(fnFs[i], fnRs[i]),
                               fout=c(filtFs[i], filtRs[i]),
                               trimLeft=trim_left,
                               truncLen=c(args$f_trunc, args$r_trunc),
                               maxN=0,
                               maxEE=maxEE,
                               truncQ=truncQ,
                               compress=TRUE,
                               verbose=TRUE)
    }
  })
}

main(commandArgs(trailingOnly=TRUE))
## invisible(warnings())


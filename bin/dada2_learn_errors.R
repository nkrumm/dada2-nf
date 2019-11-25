#!/usr/bin/env Rscript

## provides fastq_files()
source(file.path(
    normalizePath(dirname(gsub('--file=', '', grep('--file', commandArgs(), value=TRUE)))),
    'dada2_common.R'))

suppressWarnings(suppressMessages(library(ggplot2, quietly = TRUE)))
suppressWarnings(suppressMessages(library(gridExtra, quietly = TRUE)))
suppressWarnings(suppressMessages(library(argparse, quietly = TRUE)))
suppressWarnings(suppressMessages(library(dada2, quietly = TRUE)))


errplot <- function(err, title=""){
  dada2::plotErrors(err, nominalQ=TRUE) +
    ggtitle(title) +
    theme(aspect.ratio=1)
}


main <- function(arguments){
  parser <- ArgumentParser()
  parser$add_argument('path', help='path containing filtered fastq files')
  parser$add_argument('--model', help='output .rds file containing the model',
                      default='error_model.rds')
  parser$add_argument('--plots', help='optional file for output of dada2::plotErrors()')
  parser$add_argument('--nthreads', type='integer', default=0,
                      help='number of processes; defaults to number available')

  args <- parser$parse_args(arguments)

  multithread <- if(args$nthreads == 0){ TRUE }else{ args$nthreads }

  fastqs <- fastq_files(list.files(args$path, pattern='.fastq.gz$', full.names=TRUE))

  cat('generating error model for forward reads\n')
  errF <- dada2::learnErrors(fastqs$fnFs, multithread=multithread)
  cat('generating error model for reverse reads\n')
  errR <- dada2::learnErrors(fastqs$fnRs, multithread=multithread)

  cat(gettextf('saving error model to %s\n', args$model))
  saveRDS(list(errF=errF, errR=errR), file=args$model)

  if(!is.null(args$plots)){
    fig <- gridExtra::grid.arrange(errplot(errF, "forward"),
                                   errplot(errR, "reverse"),
                                   nrow=1)
    ggplot2::ggsave(args$plots, fig)
  }

}

main(commandArgs(trailingOnly=TRUE))
## invisible(warnings())


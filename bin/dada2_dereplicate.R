#!/usr/bin/env Rscript

## provides fastq_files()
source(file.path(
    normalizePath(dirname(gsub('--file=', '', grep('--file', commandArgs(), value=TRUE)))),
    'dada2_common.R'))

suppressPackageStartupMessages(library(argparse, quietly = TRUE))
suppressPackageStartupMessages(library(dada2, quietly = TRUE))

do_dada <- function(filtered, sample.names, err=NULL, selfConsist=TRUE, ...){
  derep <- dada2::derepFastq(filtered)
  if(class(derep) == 'derep'){
    ## list instead if bare derep object for single sample
    derep=list(derep)
  }
  names(derep) <- sample.names
  model <- dada2::dada(derep, err=err, selfConsist=selfConsist, ...)
  list(derep=derep, model=model)
}

main <- function(arguments){
  parser <- ArgumentParser()
  parser$add_argument('path', help='path containing filtered fastq files')
  parser$add_argument('--rdata', default='dada2.rda')
  parser$add_argument('--seqtab-nochim', default='seqtab_nochim.rda')
  parser$add_argument(
             '--nthreads', type='integer',
             help='number of processes; can also be provided using DADA2_NPROC')
  parser$add_argument('--pool', action='store_true', default=FALSE)
  parser$add_argument('--subsample', type='integer',
                      help='process a random subset of N specimens')
  parser$add_argument('--max-mismatch', type='integer', default=0,
                      help='The maximum mismatches allowed in the overlap region.')
  parser$add_argument('--max-indels', type='integer', default=16,
                      help='The maximum number of cumulative indels a sequence may contain compared to a more abundant variant to be considered for grouping.')

  args <- parser$parse_args(arguments)

  multithread <- if(nchar(Sys.getenv('DADA2_NPROC')) != 0){
                   as.integer(Sys.getenv('DADA2_NPROC'))
                 }else if(!is.null(args$nthreads)){
                   args$nthreads
                 }else{
                   FALSE
                 }

  fastqs <- fastq_files(list.files(args$path, pattern='.fastq.gz$', full.names=TRUE))

  with(fastqs, {
    if(!is.null(args$subsample)){
      ii <- sample(seq_along(fnFs), args$subsample)
      fnFs <- fnFs[ii]
      fnRs <- fnRs[ii]
      sample.names <- sample.names[ii]
    }

    cat('generating error model for forward reads\n')
    f <- do_dada(fnFs,
                 sample.names,
                 pool=args$pool,
                 multithread=multithread,
                 BAND_SIZE=args$max_indels)

    cat('generating error model for reverse reads\n')
    r <- do_dada(fnRs,
                 sample.names,
                 pool=args$pool,
                 multithread=multithread,
                 BAND_SIZE=args$max_indels)

    cat('merging reads\n')
    merged <- dada2::mergePairs(
                         dadaF=f$model,
                         derepF=f$derep,
                         dadaR=r$model,
                         derepR=r$derep,
                         maxMismatch=args$max_mismatch,
                         verbose=TRUE)

    cat('making sequence table\n')
    seqtab <- dada2::makeSequenceTable(merged)
    rownames(seqtab) <- sample.names

    cat('checking for chimeras\n')
    seqtab.nochim <- dada2::removeBimeraDenovo(seqtab, verbose=TRUE)
    rownames(seqtab.nochim) <- sample.names

    save(seqtab.nochim, file=args$seqtab_nochim)

    save(f, r, merged, seqtab, seqtab.nochim, sample.names, file=args$rdata)
  })
}

main(commandArgs(trailingOnly=TRUE))
## invisible(warnings())


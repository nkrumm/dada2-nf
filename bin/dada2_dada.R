#!/usr/bin/env Rscript

suppressWarnings(suppressMessages(library(argparse, quietly = TRUE)))
suppressWarnings(suppressMessages(library(dada2, quietly = TRUE)))

do_dada <- function(filtered, sample.names, err=NULL, ...){
  derep <- dada2::derepFastq(filtered)

  if(class(derep) == 'derep'){
    ## list instead of bare derep object for single sample
    derep=list(derep)
  }
  names(derep) <- sample.names
  dada <- dada2::dada(derep, err=err, ...)
  list(derep=derep, dada=dada)
}

main <- function(arguments){
  parser <- ArgumentParser()
  parser$add_argument('r1', help='path to fastq for R1')
  parser$add_argument('r2', help='path to fastq for R2')
  parser$add_argument('-s', '--sampleid', default='unknown', help='label for this specimen')
  parser$add_argument('--errors',
                      help=paste('.rds file containing error model',
                                 '(a list with values "errF" and "errR").',
                                 'Calculates error model for this specimen if not provided.'))

  ## outputs
  parser$add_argument('--dada2-data', default='dada2_data.rds',
                      help="output .rds file containing intermediate data structures")
  parser$add_argument('--seqtab-nochim', default='seqtab_nochim.rds',
                      help="output .rds containing chimera-checked seqtab")
  parser$add_argument('--counts', default='counts.csv',
                      help="input and output read counts")
  parser$add_argument('--overlaps', default='overlaps.csv',
                      help="distribution of overlaps among merged reads")


  ## parameters
  parser$add_argument('--self-consist', default='TRUE', choices=c('TRUE', 'FALSE'),
                      help='value for dad2::dada(selfConsist) [%(default)s]')
  parser$add_argument('--max-mismatch', type='integer', default=0,
                      help='The maximum mismatches allowed in overlap [%(default)s]')
  parser$add_argument('--max-indels', type='integer', default=16,
                      help=paste('sets dada2::dada(BAND_SIZE), ',
                                 'essentially the maximum number of cumulative indels',
                                 'a sequence may contain compared to a more',
                                 'abundant variant to be considered for grouping.',
                                 '[%(default)s]'))

  parser$add_argument('--nthreads', type='integer', default=0,
                      help='number of processes; defaults to number available')


  args <- parser$parse_args(arguments)

  multithread <- if(args$nthreads == 0){ TRUE }else{ args$nthreads }

  fnFs <- args$r1
  fnRs <- args$r2

  if(is.null(args$errors)){
    errors <- list()
  }else{
    cat(gettextf('using errors in %s\n', args$errors))
    errors <- readRDS(args$errors)
  }

  cat('dereplicating and applying error model for forward reads\n')
  f <- do_dada(fnFs,
               sample.names=args$sampleid,
               err=errors$errF,
               ## additional arguments for dada2::dada
               multithread=multithread,
               selfConsist=as.logical(args$self_consist),
               BAND_SIZE=args$max_indels)

  cat('dereplicating and applying error model for reverse reads\n')
  r <- do_dada(fnRs,
               sample.names=args$sampleid,
               err=errors$errR,
               ## additional arguments for dada2::dada
               multithread=multithread,
               selfConsist=as.logical(args$self_consist),
               BAND_SIZE=args$max_indels)

  cat('merging reads\n')
  merged <- dada2::mergePairs(
                       dadaF=f$dada,
                       derepF=f$derep,
                       dadaR=r$dada,
                       derepR=r$derep,
                       maxMismatch=args$max_mismatch,
                       verbose=TRUE)

  cat('making sequence table\n')
  seqtab <- dada2::makeSequenceTable(merged)
  rownames(seqtab) <- args$sampleid

  cat('checking for chimeras\n')
  seqtab.nochim <- dada2::removeBimeraDenovo(seqtab, multithread=multithread, verbose=TRUE)
  rownames(seqtab.nochim) <- args$sampleid

  saveRDS(seqtab.nochim, file=args$seqtab_nochim)
  saveRDS(list(sampleid=args$sampleid, f=f, r=r, merged=merged,
               seqtab=seqtab, seqtab.nochim=seqtab.nochim),
          file=args$dada2_data)

  ## read counts for various stages of the analysis
  getN <- function(x){ sum(dada2::getUniques(x)) }
  counts <- data.frame(
      sampleid=args$sampleid,
      filtered_and_trimmed=getN(f$derep[[1]]),
      denoised_r1=getN(f$dada),
      denoised_r2=getN(r$dada),
      merged=getN(merged),
      no_chimeras=rowSums(seqtab.nochim)
  )
  write.csv(counts, file=args$counts, row.names=FALSE)

  ## calculate overlaps among merged reads
  overlaps <- data.frame(aggregate(abundance ~ nmatch, merged, sum))
  overlaps$sampleid <- args$sampleid
  write.csv(overlaps[, c('sampleid', 'nmatch', 'abundance')],
            file=args$overlaps, row.names=FALSE)

}

main(commandArgs(trailingOnly=TRUE))
## invisible(warnings())


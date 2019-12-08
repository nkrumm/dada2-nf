#!/usr/bin/env Rscript

suppressWarnings(suppressMessages(library(argparse, quietly = TRUE)))
suppressWarnings(suppressMessages(library(dada2, quietly = TRUE)))
suppressWarnings(suppressMessages(library(ggplot2, quietly = TRUE)))

na.ifnull <- function(val){
  if(is.null(val)){
    NA
  }else{
    val
  }
}

## read.fq <- function(fname, hash.prop=1){
##   temp <- tempfile(fileext=".fastq")
##   system2('gunzip', c('-d', '--stdout', fname), stdout=temp)
##   s.fastq <- qrqc::readSeqFile(temp, hash.prop=hash.prop)
##   unlink(temp)
##   s.fastq
## }

gzip_size <- function(fname){
  ## TODO: this is liklely to be pretty fragile
  ## stdout looks something like
  ## [1] "         compressed        uncompressed  ratio uncompressed_name"
  ## [2] "                 53                   0   0.0% filename
  out <- system2('gunzip', c('-l', fname), stdout=TRUE)
  as.integer(unlist(strsplit(out[2], "\\s+"))[3])
}

main <- function(arguments){

  parser <- ArgumentParser()
  parser$add_argument('r1', help='fastq.gz containing forward read')
  parser$add_argument('r2', help='fastq.gz containing reverse read')
  parser$add_argument('-o', '--outfile', default='plot_quality.png')
  parser$add_argument('--specimen', default='specimen',
                      help='specimen identifier for title')

  parser$add_argument('--nreads', type='double', default=100000)
  parser$add_argument('--trim-left', type='double', default=1)
  parser$add_argument('--f-trunc', type='double')
  parser$add_argument('--r-trunc', type='double')

  args <- parser$parse_args(arguments)

  trim_left <- na.ifnull(args$trim_left)
  f_trunc <- na.ifnull(args$f_trunc)
  r_trunc <- na.ifnull(args$r_trunc)

  height = 480
  if(gzip_size(args$r1) == 0){
    png(args$outfile, width=height * 2, height=height)
    plot.new()
    title(gettextf('%s is empty', args$specimen))
    invisible(dev.off())
    quit()
  }

  p.r1 <- dada2::plotQualityProfile(args$r1, args$nreads)
  p.r2 <- dada2::plotQualityProfile(args$r2, args$nreads)

  ## mark positions at which reads will be trimmed
  p.r1 <- p.r1 +
    ggtitle(gettextf('%s R1: trim_left: %s  f_trunc: %s',
                     args$specimen, trim_left, f_trunc)) +
    geom_vline(xintercept=c(trim_left, f_trunc))

  if(!is.null(args$trim_left)){
    p.r2 <- p.r2 +
      ggtitle(gettextf('%s R2: trim_left: %s  r_trunc: %s',
                       args$specimen, trim_left, r_trunc)) +
      geom_vline(xintercept=c(trim_left, r_trunc))}

  fig <- gridExtra::grid.arrange(p.r1, p.r2, nrow=1)

  ## ggsave fonts are less pleasing by default...
  ## ggplot2::ggsave(args$outfile, fig, width=10, height=4, units="in")

  png(args$outfile, width=height * 2, height=height)
  plot(fig)
  invisible(dev.off())
}

main(commandArgs(trailingOnly=TRUE))

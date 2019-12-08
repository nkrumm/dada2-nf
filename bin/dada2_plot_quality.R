#!/usr/bin/env Rscript

suppressWarnings(suppressMessages(library(argparse, quietly = TRUE)))
## suppressWarnings(suppressMessages(library(dada2, quietly = TRUE)))
## suppressWarnings(suppressMessages(library(ggplot2, quietly = TRUE)))

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
  parser$add_argument('-o', '--outfile', default='plot_quality.svg')
  ## parser$add_argument('--title', default='quality plot')

  parser$add_argument('--nreads', type='double', default=100000)
  parser$add_argument('--trim-left', type='double')
  parser$add_argument('--f-trunc', type='double')
  parser$add_argument('--r-trunc', type='double')

  args <- parser$parse_args(arguments)

  if(gzip_size(args$r1) == 0){
    svg(args$outfile, width=10, height=4)
    plot.new()
    title(gettextf('%s is empty', basename(args$r1)))
    invisible(dev.off())
    quit()
  }

  p.r1 <- dada2::plotQualityProfile(args$r1, args$nreads)
  p.r2 <- dada2::plotQualityProfile(args$r2, args$nreads)

  ## mark positions at which reads will be trimmed
  if(!is.null(args$trim_left)){
    p.r1 <- p.r1 + geom_vline(
                 xintercept=c(na.ifnull(args$trim_left), na.ifnull(args$f_trunc)))}

  if(!is.null(args$trim_left)){
    p.r2 <- p.r2 + geom_vline(
                 xintercept=c(na.ifnull(args$trim_left), na.ifnull(args$r_trunc)))}

  fig <- gridExtra::grid.arrange(p.r1, p.r2, nrow=1)

  ## ggsave fonts are less pleasing by default...
  ## ggplot2::ggsave(args$outfile, fig, width=10, height=4, units="in")

  svg(args$outfile, width=10, height=4)
  plot(fig)
  invisible(dev.off())
}

main(commandArgs(trailingOnly=TRUE))

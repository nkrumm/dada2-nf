#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(argparse, quietly = TRUE))
suppressPackageStartupMessages(library(qrqc, quietly = TRUE))

read.fq <- function(fname, hash.prop=1){
  temp <- tempfile(fileext=".fastq")
  system2('gunzip', c('-d', '--stdout', fname), stdout=temp)
  s.fastq <- qrqc::readSeqFile(temp, hash.prop=hash.prop)
  unlink(temp)
  s.fastq
}

na.ifnull <- function(val){
  if(is.null(val)){
    NA
  }else{
    val
  }
}

main <- function(arguments){

  parser <- ArgumentParser()
  parser$add_argument('fwd', help='fastq.gz containing forward read')
  parser$add_argument('rev', help='fastq.gz containing reverse read')
  parser$add_argument('-o', '--outfile', default='plot_quality.svg')
  parser$add_argument('--title', default='quality plot')

  parser$add_argument('--trim-left', type='double')
  parser$add_argument('--f-trunc', type='double')
  parser$add_argument('--r-trunc', type='double')

  args <- parser$parse_args(arguments)

  fqlist = lapply(list(args$fwd, args$rev), read.fq)
  ## TODO: could add --labels to override R1,R2
  names(fqlist) <- sapply(seq_along(fqlist), function(i){gettextf('R%s', i)})

  svg(args$outfile, width=7, height=4)
  p <- qrqc::qualPlot(fqlist) +
    ylim(c(0, 40)) +
    ggtitle(args$title)

  ## mark positions at which reads were trimmed

  ## the 'aes' method results in a different value (specified by
  ## 'xintercept') in each panel (identified by the column 'sample' -
  ## had to look at the source code for qualPlot to determine that
  ## plots are faceted on 'sample')
  if(!is.null(args$trim_left)){
    p <- p + geom_vline(aes(xintercept=xintercept),
                        data.frame(
                            sample=names(fqlist),
                            xintercept=rep(args$trim_left, 2)
                        ))
  }

  if(!is.null(args$f_trunc) || !is.null(args$r_trunc)){
    p <- p + geom_vline(aes(xintercept=xintercept),
                        data.frame(
                            sample=names(fqlist),
                            xintercept=c(na.ifnull(args$f_trunc),
                                         na.ifnull(args$r_trunc))
                        ))
  }

  plot(p)
  invisible(dev.off())
}

main(commandArgs(trailingOnly=TRUE))

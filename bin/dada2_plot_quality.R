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

main <- function(arguments){

  parser <- ArgumentParser()
  parser$add_argument('r1', help='fastq.gz containing forward read')
  parser$add_argument('r2', help='fastq.gz containing reverse read')
  parser$add_argument('-o', '--outfile', default='plot_quality.svg')
  parser$add_argument('--title', default='quality plot')

  parser$add_argument('--nreads', type='double', default=10000)
  parser$add_argument('--trim-left', type='double')
  parser$add_argument('--f-trunc', type='double')
  parser$add_argument('--r-trunc', type='double')

  args <- parser$parse_args(arguments)

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

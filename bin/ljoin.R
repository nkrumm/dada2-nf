#!/usr/bin/env Rscript

suppressWarnings(suppressMessages(library(argparse, quietly = TRUE)))
suppressWarnings(suppressMessages(library(readr, quietly = TRUE)))
suppressWarnings(suppressMessages(library(dplyr, quietly = TRUE)))
suppressWarnings(suppressMessages(library(tidyr, quietly = TRUE)))

main <- function(arguments){
  parser <- ArgumentParser()
  parser$add_argument('tabs', nargs='+')
  parser$add_argument('-o', '--outfile', default='joined.csv')

  args <- parser$parse_args(arguments)
  tabs <- lapply(args$tabs, read_csv)
  firstcol <- colnames(tabs[[1]])[1]

  joined <- Reduce(function(l, r){left_join(l, r, by=firstcol)}, tabs)
  joined <- replace_na(
      joined, as.list(sapply(colnames(joined), function(x){0})))

  write.csv(joined, file=args$outfile, row.names=FALSE)
}

main(commandArgs(trailingOnly=TRUE))
## invisible(warnings())


#!/bin/bash

# Concatenate (stack) csv files with headers to stdout.

# Includes the header line from the first file; others are
# omitted. Supports bzip2 and gzip compressed files; each file must
# have a suffix of .bz2, .gz, or .csv

set -e

function catcmd(){
    if [[ "$1" == *.bz2 ]]; then
	catcmd=bzcat
    elif [[ "$1" == *.gz ]]; then
	catcmd=zcat
    elif [[ "$1" == *.csv ]]; then
	catcmd=cat
    else
	echo "unsupported suffix in $1 (must be one of .bz2 .gz .csv)"
	exit 1
    fi
    echo $catcmd
}

if [[ -z $1 ]]; then
    echo "usage: csvcat.sh infile1.csv[.bz2,.gz] [infile2.csv[.bz2,.gz], ...]"
fi

args=( "$@" )

# include the entirety of the first file
first="${args[0]}"
echo $first 1>&2
cmd=$(catcmd "$first") || (echo $cmd; exit 1)
$cmd "$first" | tr -d '\015'

# ...but remove the header line from the rest
for f in "${args[@]:1}"; do
    echo $f 1>&2
    cmd=$(catcmd "$f") || (echo $cmd; exit 1)
    $cmd "$f" | tail -n+2 | tr -d '\015'
done

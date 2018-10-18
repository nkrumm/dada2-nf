#!/bin/bash

set -e

label=1.8
sha=630ef9ac993267eda7224ba5326600c3aaff8a6f

if [[ $1 == '-h' ]]; then
    echo "usage: ./build.sh [label] [commit-sha]"
    echo "- label identifies the dada2 version in the image file name [$label]"
    echo "- sha is the dada2 commit to install [$sha]"
    exit
fi

outdir=$(readlink -f ${2-.})

label=${1-$label}
sha=${2-$sha}

img=dada2-${label}-singularity$(singularity --version).simg
singfile=$(mktemp Singularity-XXXXXX)
sed s"/SHA/$sha/" < Singularity > $singfile

if [[ ! -f $img ]]; then
    sudo singularity build $img $singfile
fi

rm -f $singfile


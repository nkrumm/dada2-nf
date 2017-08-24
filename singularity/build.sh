#!/bin/bash

set -e

if [[ -z $1 ]]; then
    echo "usage: ./build.sh <tag> [<outdir>]"
    exit 1
fi

outdir=$(readlink -f ${2-.})

tag=$1
img=dada2-${tag}.img
singfile=$(mktemp Singularity-XXXXXX)
sed s"/TAG/$tag/" < Singularity > $singfile

if [[ ! -f $img ]]; then
    singularity create --size 3000 $img
    sudo singularity bootstrap $img $singfile
fi

rm $singfile


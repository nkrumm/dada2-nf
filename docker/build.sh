#!/bin/bash

if [[ -z $1 ]]; then
    tag=$(git describe --tags --dirty)
else
    tag=$1
fi

if ! git diff-index --quiet HEAD; then
    echo "Error: git repo is dirty - commit and try again"
    echo
    git status
    exit 1
fi

echo "building docker image dada2:$tag"
time docker build --rm --force-rm -t dada2:$tag .

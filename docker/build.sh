#!/bin/bash

set -e

if ! git diff-index --quiet HEAD; then
    echo "Error: git repo is dirty - commit and try again"
    echo
    git status
    exit 1
fi

repo=dada2-nf
version=${1-v1.12}
rev=$(git describe --tags --dirty)
python3 get_tag.py $version > /dev/null
DADA2_COMMIT=$(python3 get_tag.py $version)
tag="${repo}:${version}-${rev}"

echo "building image $tag from commit $DADA2_COMMIT"
time docker build --build-arg DADA2_COMMIT=$DADA2_COMMIT --rm --force-rm -t "$tag" .

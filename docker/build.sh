#!/bin/bash

set -e

# if ! git diff-index --quiet HEAD; then
#     echo "Error: git repo is dirty - commit and try again"
#     echo
#     git status
#     exit 1
# fi

tag=${1-v1.8}
python3 get_tag.py $tag > /dev/null
DADA2_COMMIT=$(python3 get_tag.py $tag)
echo "building image dada2:$tag from commit $DADA2_COMMIT"

time docker build --build-arg DADA2_COMMIT=$DADA2_COMMIT --rm --force-rm -t dada2:$tag .

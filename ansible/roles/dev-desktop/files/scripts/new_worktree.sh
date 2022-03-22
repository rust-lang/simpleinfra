#!/usr/bin/env sh

set -ex

N=$(ls | grep -E -e "rust[0-9]+" | wc -l)
echo $N
pushd rust0
git worktree add --detach ../rust$N
popd
pushd rust$N
git fetch upstream
git checkout upstream/master
ln -s ../config.toml
popd

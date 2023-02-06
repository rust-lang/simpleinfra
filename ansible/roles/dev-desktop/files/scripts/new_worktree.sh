#!/usr/bin/env bash

set -ex

cd ~
N=$(ls | grep -E -e "rust[0-9]+" | wc -l)
echo $N
pushd rust
git worktree add --detach ../rust$N
popd
pushd rust$N
git fetch upstream
git checkout upstream/master
ln -s ../config.toml
popd

link_rust.sh

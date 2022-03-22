#!/usr/bin/env bash

git clone git@github.com:`id -u -n`/rust.git
pushd rust
git remote add upstream git@github.com:rust-lang/rust.git
git fetch upstream
git checkout upstream/master
popd
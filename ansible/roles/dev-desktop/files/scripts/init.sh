#!/usr/bin/env bash

username=`id -u -n`
gh_name=${username#"gh-"}

git clone git@github.com:$gh_name/rust.git
pushd rust
git remote add upstream git@github.com:rust-lang/rust.git
git fetch upstream
git checkout upstream/master
popd

#!/usr/bin/env bash

username=`id -u -n`
gh_name=${username#"gh-"}

# Using https instead of git urls because vscode only handles login on push/pull
git clone https://github.com/$gh_name/rust.git
pushd rust
git remote add upstream https://github.com/rust-lang/rust.git
git fetch upstream
git checkout upstream/master
popd

init_git.py
setup_rustup.sh

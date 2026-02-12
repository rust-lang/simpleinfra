#!/usr/bin/env bash

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

username=$(id -u -n)
gh_name=${username#"gh-"}

set -x

if [[ ! -d "rust" ]]; then
  # Using https instead of git urls because vscode only handles login on push/pull
  git clone "https://github.com/${gh_name}/rust.git"
fi

pushd rust

if ! git remote | grep upstream; then
  git remote add upstream https://github.com/rust-lang/rust.git
fi

git fetch upstream
git checkout upstream/main
popd

set_defaults.sh
link_rust.sh

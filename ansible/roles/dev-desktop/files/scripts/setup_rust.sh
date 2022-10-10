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
git checkout upstream/master
popd

set_defaults.sh

for D in rust*; do
    if [ -d "${D}" ]; then
        cd "${D}" && ./x.py build
        rustup toolchain link "$D"_stage1 "$D/build/x86_64-unknown-linux-gnu/stage1"
        rustup toolchain link "$D"_stage2 "$D/build/x86_64-unknown-linux-gnu/stage2"
    fi
done

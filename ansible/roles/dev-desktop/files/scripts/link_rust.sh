#!/usr/bin/env bash

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Discover target triple (e.g. "aarch64-unknown-linux-gnu")
target="$(rustc -vV | awk '/host/ { print $2 }')"

for D in rust*; do
  if [ -d "${D}" ]; then
    pushd "${D}"

    ./x.py build

    if [[ -d "$D/build/$target/stage1" ]]; then
      rustup toolchain link "$D"_stage1 "$D/build/$target/stage1"
    fi

    if [[ -d "$D/build/$target/stage2" ]]; then
      rustup toolchain link "$D"_stage2 "$D/build/$target/stage2"
    fi

    popd
  fi
done

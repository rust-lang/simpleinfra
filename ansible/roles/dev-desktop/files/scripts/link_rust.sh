#!/usr/bin/env bash

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

for D in rust*; do
  if [ -d "${D}" ]; then
    pushd "${D}"

    ./x.py build

    if [[ -d "$D/build/aarch64-unknown-linux-gnu/stage1" ]]; then
      rustup toolchain link "$D"_stage1 "$D/build/aarch64-unknown-linux-gnu/stage1"
    fi

    if [[ -d "$D/build/aarch64-unknown-linux-gnu/stage2" ]]; then
      rustup toolchain link "$D"_stage2 "$D/build/aarch64-unknown-linux-gnu/stage2"
    fi

    popd
  fi
done

#!/usr/bin/env bash

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

for D in rust*; do
    if [ -d "${D}" ]; then
        pushd "${D}" || exit
          if [[ ! -f config.toml ]]; then
            ln -s ~/config.toml .
          fi
        popd || exit
    fi
done
